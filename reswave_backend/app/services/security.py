"""
RESWAVE - Security & Firebase Auth Token Verification
Production requests verify Firebase ID tokens. The local development fallback
uses registered profile UIDs for API requests and accepts Firebase UID headers
while creating or locating local profiles.
"""
import os
import json
import logging
from typing import Dict, Any, Optional
from fastapi import HTTPException, Header, Depends, status

logger = logging.getLogger(__name__)
_firebase_initialized = False


def is_local_mode() -> bool:
    return bool(os.environ.get("RESWAVE_LOCAL_MODE"))


try:
    import firebase_admin
    from firebase_admin import auth as firebase_auth, credentials
    from google.auth.exceptions import GoogleAuthError
except ImportError as error:
    logger.warning(
        "Firebase Admin SDK is unavailable because a dependency could not be imported (%s).",
        type(error).__name__,
    )
else:
    project_id = os.environ.get("FIREBASE_PROJECT_ID") or "reswave"
    credential_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    try:
        if credential_path and not os.path.isfile(credential_path):
            raise FileNotFoundError(
                "The configured GOOGLE_APPLICATION_CREDENTIALS file does not exist."
            )

        try:
            firebase_app = firebase_admin.get_app()
        except ValueError:
            firebase_app = None

        if firebase_app is None:
            firebase_credential = credentials.ApplicationDefault()
            firebase_credential.get_credential()
            credential_project_id = firebase_credential.project_id
            if credential_project_id and credential_project_id != project_id:
                raise ValueError(
                    "The ADC project ID does not match FIREBASE_PROJECT_ID."
                )
            firebase_app = firebase_admin.initialize_app(
                firebase_credential,
                options={"projectId": project_id},
            )
        else:
            firebase_app.credential.get_credential()
            credential_project_id = firebase_app.credential.project_id
            if credential_project_id and credential_project_id != project_id:
                raise ValueError(
                    "The initialized Firebase credential project ID does not match "
                    "FIREBASE_PROJECT_ID."
                )

        if firebase_app.project_id != project_id:
            raise ValueError(
                "The initialized Firebase project ID does not match FIREBASE_PROJECT_ID."
            )
        _firebase_initialized = True
    except (GoogleAuthError, OSError, ValueError) as error:
        logger.warning(
            "Firebase Admin SDK initialization failed (%s).",
            type(error).__name__,
        )

def verify_firebase_identity(
    authorization: Optional[str],
    firebase_uid: Optional[str] = None,
) -> Dict[str, Any]:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="UNAUTHENTICATED: Missing or malformed Bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = authorization.split(" ", 1)[1].strip()
    if _firebase_initialized and not is_local_mode():
        try:
            decoded_token = firebase_auth.verify_id_token(token)
            verified_uid = decoded_token["uid"]
            if firebase_uid and firebase_uid != verified_uid:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="INVALID_TOKEN: Firebase UID does not match the ID token",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            return {
                "uid": verified_uid,
                "email": decoded_token.get("email", ""),
                "emailVerified": decoded_token.get("email_verified", False),
                "isAdmin": decoded_token.get("admin", False) or (decoded_token.get("role") == "admin"),
            }
        except HTTPException:
            raise
        except Exception as error:
            logger.warning(
                "Firebase ID token verification failed (%s).",
                type(error).__name__,
            )
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="FIREBASE_ID_TOKEN_INVALID",
                headers={"WWW-Authenticate": "Bearer"},
            )

    if not is_local_mode():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIREBASE_ADMIN_NOT_CONFIGURED",
        )

    if not firebase_uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="UNAUTHENTICATED: Firebase UID is required in local mode",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return {
        "uid": firebase_uid,
        "email": "",
        "emailVerified": False,
        "isAdmin": False,
    }


def verify_bearer_token(
    authorization: Optional[str] = Header(None),
    firebase_uid: Optional[str] = Header(None, alias="X-Firebase-UID"),
) -> Dict[str, Any]:
    """
    Verifies token header. In production, verifies Firebase ID Token cryptographically.
    Extracts UID, email, email_verified, and admin role.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="UNAUTHENTICATED: Missing or malformed Bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = authorization.split(" ")[1].strip()

    # If Firebase Admin is available and running against real Firebase
    if _firebase_initialized and not is_local_mode():
        try:
            decoded_token = firebase_auth.verify_id_token(token)
            return {
                "uid": decoded_token["uid"],
                "email": decoded_token.get("email", ""),
                "emailVerified": decoded_token.get("email_verified", False),
                "isAdmin": decoded_token.get("admin", False) or (decoded_token.get("role") == "admin"),
            }
        except Exception as error:
            logger.warning(
                "Firebase ID token verification failed (%s).",
                type(error).__name__,
            )
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="FIREBASE_ID_TOKEN_INVALID",
                headers={"WWW-Authenticate": "Bearer"},
            )

    if firebase_uid and not is_local_mode():
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="FIREBASE_ADMIN_NOT_CONFIGURED",
        )

    # Local development resolves an existing profile by Firebase UID or legacy token.
    from ..core.memory_db import db
    user = db.users.get(firebase_uid or token)
    if not user:
        # Search by email for testing
        if not firebase_uid:
            for u in db.users.values():
                if u.get("email") == token:
                    user = u
                    break

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="INVALID_SESSION: User does not exist or session expired",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if user.get("accountStatus") == "suspended":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ACCOUNT_SUSPENDED: Your account has been suspended by a moderator",
        )

    return {
        "uid": user["uid"],
        "email": user["email"],
        "emailVerified": user.get("emailVerified", False),
        "isAdmin": user.get("isAdmin", False) or (user.get("role") == "Admin / Moderator"),
    }


def get_firebase_admin_app() -> Any:
    if not _firebase_initialized:
        raise RuntimeError(
            "Firebase Admin SDK is not initialized; configure "
            "GOOGLE_APPLICATION_CREDENTIALS with the service-account JSON path."
        )
    return firebase_admin.get_app()


def require_admin(current_user: Dict[str, Any] = Depends(verify_bearer_token)) -> Dict[str, Any]:
    if not current_user.get("isAdmin", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="PERMISSION_DENIED_ADMIN_ONLY: Staff privilege required",
        )
    return current_user
