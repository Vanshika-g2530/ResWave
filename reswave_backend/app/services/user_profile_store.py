"""Firestore-backed persistence for Firebase-authenticated user profiles."""

import hashlib
from typing import Any, Dict, List, Optional

from google.cloud import firestore

from ..core.firestore_db import get_firestore_client


class UserProfileConflict(Exception):
    def __init__(self, code: str):
        self.code = code
        super().__init__(code)


def _get_firestore_client() -> Any:
    return get_firestore_client()


def get_user_profile(uid: str) -> Optional[Dict[str, Any]]:
    snapshot = (
        _get_firestore_client()
        .collection("users")
        .document(uid)
        .get()
    )

    if not snapshot.exists:
        return None

    profile = snapshot.to_dict() or {}
    profile.setdefault("uid", uid)

    return profile


def list_user_profiles() -> List[Dict[str, Any]]:
    profiles = []

    for snapshot in _get_firestore_client().collection("users").stream():
        profile = snapshot.to_dict() or {}
        profile.setdefault("uid", snapshot.id)
        profiles.append(profile)

    return profiles


def create_or_get_user_profile(
    uid: str,
    profile: Dict[str, Any],
) -> Dict[str, Any]:

    client = _get_firestore_client()

    user_ref = client.collection("users").document(uid)

    normalized_email = profile["email"].strip().lower()

    email_hash = hashlib.sha256(
        normalized_email.encode("utf-8")
    ).hexdigest()

    email_ref = client.collection("userEmailIndex").document(email_hash)

    email_query = (
        client.collection("users")
        .where("email", "==", normalized_email)
    )

    @firestore.transactional
    def create_or_get(transaction: Any) -> Dict[str, Any]:

        # Correctly retrieve document snapshots.
        user_snapshot = user_ref.get(transaction=transaction)

        email_snapshot = email_ref.get(transaction=transaction)

        # Retrieve matching email documents transactionally.
        email_matches = email_query.get(transaction=transaction)

        indexed_uid = (
            email_snapshot.get("uid")
            if email_snapshot.exists
            else None
        )

        if indexed_uid and indexed_uid != uid:
            raise UserProfileConflict("EMAIL_ALREADY_EXISTS")

        if any(snapshot.id != uid for snapshot in email_matches):
            raise UserProfileConflict("EMAIL_ALREADY_EXISTS")

        if user_snapshot.exists:

            existing_profile = user_snapshot.to_dict() or {}

            existing_profile.setdefault("uid", uid)

            existing_email = str(
                existing_profile.get("email", "")
            ).strip().lower()

            if existing_email != normalized_email:
                raise UserProfileConflict("UID_ALREADY_EXISTS")

            if existing_profile.get("accountStatus") == "suspended":
                raise UserProfileConflict("ACCOUNT_SUSPENDED")

            if not email_snapshot.exists:
                transaction.create(
                    email_ref,
                    {"uid": uid}
                )

            return existing_profile

        # Create new user profile.
        transaction.create(user_ref, profile)

        if not email_snapshot.exists:
            transaction.create(
                email_ref,
                {"uid": uid}
            )

        return profile

    return create_or_get(client.transaction())


def update_user_profile(
    uid: str,
    updates: Dict[str, Any],
) -> Optional[Dict[str, Any]]:

    client = _get_firestore_client()

    user_ref = client.collection("users").document(uid)

    @firestore.transactional
    def update(transaction: Any) -> Optional[Dict[str, Any]]:

        snapshot = user_ref.get(transaction=transaction)

        if not snapshot.exists:
            return None

        transaction.update(user_ref, updates)

        profile = snapshot.to_dict() or {}

        profile.update(updates)

        return profile

    return update(client.transaction())