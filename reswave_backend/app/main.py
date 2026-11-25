"""
RESWAVE - Canonical FastAPI Mobile Backend Service
Version 3.0 | Complete Specification Implementation
Single canonical backend serving Flutter Android application.
"""
import uuid
import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator, List, Dict, Any, Optional
from fastapi import FastAPI, HTTPException, Header, Depends, Query, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from .core.memory_db import db, utc_now_iso
from .core.firestore_db import FirestoreTransactionEngine
from .services.security import (
    is_local_mode,
    verify_bearer_token,
    verify_firebase_identity,
    require_admin,
)
from .services.user_profile_store import (
    UserProfileConflict,
    create_or_get_user_profile,
    get_user_profile,
    list_user_profiles,
    update_user_profile,
)
from .models.schemas import (
    UserCreate, UserResponse,
    ResearchInterestCreate, ResearchInterest,
    QuestionnaireInput, DomainRecommendation,
    TeamRequestCreate, TeamRequest, TeamApplicationCreate, TeamApplication,
    MoodCheckinCreate, MoodEntry, PeerSupportPostCreate, PeerSupportPost,
    PaperLibraryItem, Publication, LearningResource, Opportunity,
    ModerationReportCreate, ModerationReport,
    ConnectionRequestCreate, ConnectionRequestResponse, NetworkSummaryResponse,
    MentorQuestionnaireInput, MentorDecisionRequest, MentorProfile, MentorRequestCreate,
    CommentCreate, CommentResponse, SendMessageRequest, MessageResponse, ConversationResponse,
    GroupCreate, ProjectTaskCreate, ProjectMilestoneCreate, FCMTokenRequest,
    FeedPostCreate, FeedPost, Group, ProjectTask, ProjectMilestone
)
from .services.domain_finder import score_domain_against_questionnaire, determine_fit_band
from .services.matching_engine import (
    score_researcher_match,
    score_teammate_for_request,
    score_mentor_match,
    score_group_recommendation
)
from .services.seed_data import EMERGENCY_SUPPORT_RESOURCES

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncGenerator[None, None]:
    if not is_local_mode():
        try:
            profiles = list_user_profiles()
        except Exception as error:
            logger.exception(
                "Firestore user profile cache hydration failed (%s).",
                type(error).__name__,
            )
        else:
            for profile in profiles:
                uid = profile.get("uid")
                if uid:
                    db.cache_user_profile(uid, profile, firestore_backed=True)
    yield


app = FastAPI(
    title="ResWave Mobile API Service",
    version="3.0.0",
    description="Academic Research Journey & Community Application Backend",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _load_user_profile(
    uid: str,
    legacy_profile: Optional[Dict[str, Any]] = None,
    verified_email: Optional[str] = None,
) -> Optional[Dict[str, Any]]:
    if is_local_mode():
        return db.users.get(uid)

    try:
        profile = get_user_profile(uid)
        firestore_backed = profile is not None
        if profile is None:
            legacy_profile = legacy_profile or db.users.get(uid)
            if not legacy_profile or legacy_profile.get("uid", uid) != uid:
                return None
            if not verified_email:
                profile = legacy_profile
            elif str(legacy_profile.get("email", "")).lower() != verified_email.lower():
                return None
            else:
                profile = create_or_get_user_profile(uid, legacy_profile)
                firestore_backed = True
    except UserProfileConflict as error:
        error_status = (
            status.HTTP_403_FORBIDDEN
            if error.code == "ACCOUNT_SUSPENDED"
            else status.HTTP_409_CONFLICT
        )
        raise HTTPException(status_code=error_status, detail=error.code)
    except Exception as error:
        logger.exception(
            "Firestore user profile read failed (%s).",
            type(error).__name__,
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="PROFILE_STORE_UNAVAILABLE",
        )

    if profile is not None:
        db.cache_user_profile(uid, profile, firestore_backed=firestore_backed)
    return profile


def _persist_user_profile_updates(
    uid: str,
    updates: Dict[str, Any],
) -> Optional[Dict[str, Any]]:
    if is_local_mode():
        profile = db.users.get(uid)
        if profile is None:
            return None
        profile.update(updates)
        db.save_to_disk()
        return profile

    try:
        profile = update_user_profile(uid, updates)
    except Exception as error:
        logger.exception(
            "Firestore user profile update failed (%s).",
            type(error).__name__,
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="PROFILE_STORE_UNAVAILABLE",
        )

    if profile is None:
        return None
    db.cache_user_profile(uid, profile, firestore_backed=True)
    return profile

# ==================== Health ====================
@app.get("/health")
def health_check():
    return {"status": "ok", "service": "reswave-mobile-api", "version": "3.0.0"}

# ==================== Auth & Profile ====================
class LoginRequest(BaseModel):
    email: str
    password: Optional[str] = None

@app.post("/v1/auth/signup")
def signup(
    data: UserCreate,
    authorization: Optional[str] = Header(None),
    firebase_uid: Optional[str] = Header(None, alias="X-Firebase-UID"),
):
    local_mode = is_local_mode()
    if not authorization and not local_mode:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="FIREBASE_ID_TOKEN_REQUIRED",
            headers={"WWW-Authenticate": "Bearer"},
        )

    firebase_identity = (
        verify_firebase_identity(authorization, firebase_uid)
        if authorization
        else None
    )
    uid = firebase_identity["uid"] if firebase_identity else f"usr-{uuid.uuid4().hex[:8]}"
    if firebase_identity and firebase_identity.get("email"):
        if firebase_identity["email"].lower() != data.email.lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="FIREBASE_EMAIL_MISMATCH",
            )

    existing_user = db.users.get(uid)
    if existing_user and existing_user["email"].lower() != data.email.lower():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="UID_ALREADY_EXISTS")
    if existing_user and existing_user.get("accountStatus") == "suspended":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="ACCOUNT_SUSPENDED")

    for existing_uid, user in db.users.items():
        if existing_uid != uid and user["email"].lower() == data.email.lower():
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="EMAIL_ALREADY_EXISTS")

    if not existing_user and data.role in ["Admin", "Admin / Moderator"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="CANNOT_SELF_ASSIGN_ADMIN")

    if existing_user:
        candidate = existing_user
    else:
        now = utc_now_iso()
        candidate = {
            "uid": uid,
            "email": data.email.lower(),
            "displayName": data.displayName.strip(),
            "role": data.role,
            "headline": data.headline,
            "bio": data.bio,
            "country": data.country,
            "city": data.city,
            "institution": data.institution,
            "department": data.department,
            "visibility": data.visibility,
            "discoverable": data.discoverable,
            "preferredCollaborationMode": data.preferredCollaborationMode,
            "notificationPreferences": data.notificationPreferences,
            "roleDetails": data.roleDetails,
            "termsAccepted": data.termsAccepted,
            "termsAcceptedVersion": "3.0",
            "termsAcceptedAt": now,
            "emailVerified": firebase_identity.get("emailVerified", False) if firebase_identity else False,
            "accountStatus": "active",
            "isAdmin": False,
            "createdAt": now,
            "updatedAt": now,
        }

    if local_mode:
        db.cache_user_profile(uid, candidate)
        db.save_to_disk()
        user_record = candidate
    else:
        try:
            user_record = create_or_get_user_profile(uid, candidate)
        except UserProfileConflict as error:
            error_status = (
                status.HTTP_403_FORBIDDEN
                if error.code == "ACCOUNT_SUSPENDED"
                else status.HTTP_409_CONFLICT
            )
            raise HTTPException(status_code=error_status, detail=error.code)
        except Exception as error:
            logger.exception(
                "Firestore signup profile persistence failed (%s).",
                type(error).__name__,
            )
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="PROFILE_STORE_UNAVAILABLE",
            )
        db.cache_user_profile(uid, user_record, firestore_backed=True)

    return {"status": "success", "user": user_record, "token": uid}

@app.post("/v1/auth/login")
def login(
    data: LoginRequest,
    authorization: Optional[str] = Header(None),
    firebase_uid: Optional[str] = Header(None, alias="X-Firebase-UID"),
):
    if authorization:
        firebase_identity = verify_firebase_identity(authorization, firebase_uid)
        if firebase_identity.get("email") and firebase_identity["email"].lower() != data.email.lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="FIREBASE_EMAIL_MISMATCH",
            )
        uid = firebase_identity["uid"]
        user = _load_user_profile(
            uid,
            db.users.get(uid),
            verified_email=data.email,
        )
        if not user or user["email"].lower() != data.email.lower():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="RESWAVE_PROFILE_NOT_FOUND",
            )
        if user.get("accountStatus") == "suspended":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="ACCOUNT_SUSPENDED")
        return {"status": "success", "user": user, "token": user["uid"]}

    for user in db.users.values():
        if user["email"].lower() == data.email.lower():
            if user.get("accountStatus") == "suspended":
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="ACCOUNT_SUSPENDED")
            return {"status": "success", "user": user, "token": user["uid"]}
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="INVALID_CREDENTIALS")

@app.post("/v1/auth/verify-email")
def verify_email(user: Dict[str, Any] = Depends(verify_bearer_token)):
    u_rec = _load_user_profile(
        user["uid"],
        verified_email=user.get("email"),
    )
    if u_rec:
        updates = {"emailVerified": True, "updatedAt": utc_now_iso()}
        _persist_user_profile_updates(user["uid"], updates)
    return {"status": "success", "emailVerified": True}

@app.get("/v1/users/me")
def get_my_profile(user: Dict[str, Any] = Depends(verify_bearer_token)):
    u_rec = _load_user_profile(
        user["uid"],
        verified_email=user.get("email"),
    )
    if not u_rec:
        raise HTTPException(status_code=404, detail="USER_NOT_FOUND")
    return u_rec

@app.put("/v1/users/me")
def update_my_profile(updates: Dict[str, Any], user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    u_rec = _load_user_profile(uid, verified_email=user.get("email"))
    if not u_rec:
        raise HTTPException(status_code=404, detail="USER_NOT_FOUND")
    updates = dict(updates)
    for key in ["uid", "email", "isAdmin", "createdAt"]:
        updates.pop(key, None)
    if "role" in updates and updates["role"] in ["Admin", "Admin / Moderator"]:
        updates.pop("role")
    updates["updatedAt"] = utc_now_iso()
    return _persist_user_profile_updates(uid, updates)

@app.delete("/v1/users/me")
def delete_my_account(user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    u_rec = _load_user_profile(uid, verified_email=user.get("email"))
    if u_rec:
        _persist_user_profile_updates(
            uid,
            {
                "displayName": "Former Member",
                "accountStatus": "deleted",
                "discoverable": False,
                "visibility": "Private",
                "updatedAt": utc_now_iso(),
            },
        )
    # 1. Permanently delete private mood records
    mood_ids = [mid for mid, m in db.moodEntries.items() if m.get("userId") == uid]
    for mid in mood_ids:
        del db.moodEntries[mid]
    # 2. Delete paper library items
    paper_ids = [pid for pid, p in db.paperLibrary.items() if p.get("userId") == uid]
    for pid in paper_ids:
        del db.paperLibrary[pid]
    # 3. Delete research interests
    int_ids = [iid for iid, i in db.researchInterests.items() if i.get("userId") == uid]
    for iid in int_ids:
        del db.researchInterests[iid]
    # 4. Remove follows and connection requests
    follow_keys = [k for k, f in db.follows.items() if f.get("followerId") == uid or f.get("targetId") == uid]
    for k in follow_keys:
        del db.follows[k]
    db.save_to_disk()
    return {"status": "deleted", "userId": uid}

@app.get("/v1/users/{uid}")
def get_user_public_profile(uid: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    u_rec = _load_user_profile(uid)
    if not u_rec:
        raise HTTPException(status_code=404, detail="USER_NOT_FOUND")
    is_owner = (uid == user["uid"])
    is_admin = user.get("isAdmin", False)
    if u_rec.get("visibility") == "Private" and not is_owner and not is_admin:
        raise HTTPException(status_code=403, detail="PROFILE_IS_PRIVATE")
    # Visible research interests
    interests = [
        i for i in db.researchInterests.values()
        if i["userId"] == uid and (is_owner or is_admin or i.get("visibility") == "Visible to members")
    ]
    # Public fields only
    return {
        "uid": u_rec["uid"],
        "displayName": u_rec["displayName"],
        "role": u_rec["role"],
        "headline": u_rec.get("headline"),
        "bio": u_rec.get("bio"),
        "country": u_rec.get("country"),
        "city": u_rec.get("city"),
        "institution": u_rec.get("institution"),
        "department": u_rec.get("department"),
        "visibility": u_rec.get("visibility"),
        "discoverable": u_rec.get("discoverable"),
        "preferredCollaborationMode": u_rec.get("preferredCollaborationMode"),
        "interests": interests
    }

# ==================== Multi-Domain Research Interests (Section 3.6) ====================
@app.get("/v1/users/me/interests")
def get_my_interests(user: Dict[str, Any] = Depends(verify_bearer_token)):
    return [i for i in db.researchInterests.values() if i["userId"] == user["uid"]]

@app.post("/v1/users/me/interests")
def add_research_interest(interest: ResearchInterestCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    int_id = f"int-{uuid.uuid4().hex[:8]}"
    rec = {
        "id": int_id,
        "userId": user["uid"],
        **interest.dict(),
        "createdAt": utc_now_iso()
    }
    db.researchInterests[int_id] = rec
    db.save_to_disk()
    return rec

@app.put("/v1/users/me/interests/{int_id}")
def update_research_interest(int_id: str, updates: Dict[str, Any], user: Dict[str, Any] = Depends(verify_bearer_token)):
    rec = db.researchInterests.get(int_id)
    if not rec or rec["userId"] != user["uid"]:
        raise HTTPException(status_code=404, detail="INTEREST_NOT_FOUND")
    for key in ["id", "userId", "createdAt"]:
        updates.pop(key, None)
    rec.update(updates)
    db.save_to_disk()
    return rec

@app.delete("/v1/users/me/interests/{int_id}")
def delete_research_interest(int_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    rec = db.researchInterests.get(int_id)
    if not rec or rec["userId"] != user["uid"]:
        raise HTTPException(status_code=404, detail="INTEREST_NOT_FOUND")
    del db.researchInterests[int_id]
    db.save_to_disk()
    return {"status": "deleted", "id": int_id}

# ==================== Research Domain Finder (Section 4) ====================
@app.get("/v1/domains")
def list_domains():
    return list(db.domains.values())

@app.post("/v1/domain-recommendations")
def get_domain_recommendations(answers: QuestionnaireInput):

    ans_dict = answers.dict()

    valid_dims = sum(
        1 for key in [
            "subjects",
            "problems",
            "workStyles",
            "skills",
            "goals"
        ]
        if any(
            str(x).strip().lower()
            not in ["", "not sure", "skip", "other"]
            for x in ans_dict.get(key, [])
        )
    )

    is_exploratory = valid_dims < 2

    results = []

    for domain in db.domains.values():

        score, reasons = score_domain_against_questionnaire(
            domain,
            ans_dict,
            is_exploratory=is_exploratory
        )

        fit_band = determine_fit_band(
            score,
            is_exploratory=is_exploratory
        )

        # Fetch resources linked to this domain
        resource_ids = domain.get("learningResourceIds", [])

        beginner_resources = []

        for resource_id in resource_ids:

            resource = db.learningResources.get(resource_id)

            if resource and resource.get("status") == "Published":
                beginner_resources.append(resource["title"])

        related_groups = [
            group["title"]
            for group in db.groups.values()
            if group.get("primaryDomain") == domain["id"]
        ]

        results.append({
            "domainId": domain["id"],
            "name": domain["name"],
            "description": domain["shortDescription"],
            "score": score,
            "fitBand": fit_band,
            "reasons": reasons,

            # Flutter model expects these exact names
            "sampleTopics": domain.get("subdomains", []),
            "requiredSkills": domain.get("skillTags", []),
            "beginnerResources": beginner_resources,

            # Additional information
            "sampleQuestions": domain.get(
                "sampleResearchQuestions", []
            ),
            "commonMethods": domain.get("commonMethods", []),
            "relatedGroups": related_groups
        })

    if not is_exploratory:
        results.sort(
            key=lambda item: item["score"],
            reverse=True
        )

    return results
# ==================== Learning Hub (Section 5) ====================
@app.get("/v1/learning/resources")
def list_learning_resources(
    domain: Optional[str] = None,
    level: Optional[str] = None,
    format: Optional[str] = None,
    query: Optional[str] = None
):
    items = [r for r in db.learningResources.values() if r.get("status") == "Published"]
    if domain:
        items = [r for r in items if any(domain.lower() in t.lower() for t in r.get("domainTags", []))]
    if level:
        items = [r for r in items if r.get("level", "").lower() == level.lower()]
    if format:
        items = [r for r in items if r.get("format", "").lower() == format.lower()]
    if query:
        q = query.lower()
        items = [r for r in items if q in r.get("title", "").lower() or q in r.get("summary", "").lower()]
    return items

@app.get("/v1/learning/progress/{res_id}")
def get_resource_progress(res_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    prog_id = f"{user['uid']}_{res_id}"
    prog = db.resourceProgress.get(prog_id)
    if not prog:
        return {"resourceId": res_id, "status": "Not started", "saved": False, "privateNotes": None}
    return prog

@app.post("/v1/learning/progress/{res_id}")
def update_resource_progress(res_id: str, payload: Dict[str, Any], user: Dict[str, Any] = Depends(verify_bearer_token)):
    prog_id = f"{user['uid']}_{res_id}"
    prog = db.resourceProgress.get(prog_id, {
        "id": prog_id,
        "userId": user["uid"],
        "resourceId": res_id,
        "status": "Not started",
        "saved": False,
        "privateNotes": None,
        "completedAt": None
    })
    if "status" in payload:
        prog["status"] = payload["status"]
        if payload["status"] == "Completed":
            prog["completedAt"] = utc_now_iso()
    if "saved" in payload:
        prog["saved"] = payload["saved"]
    if "privateNotes" in payload:
        prog["privateNotes"] = payload["privateNotes"]
    prog["updatedAt"] = utc_now_iso()
    db.resourceProgress[prog_id] = prog
    db.save_to_disk()
    return prog

# ==================== Personal Paper Library (Section 6.3) ====================
@app.get("/v1/papers")
def list_my_papers(user: Dict[str, Any] = Depends(verify_bearer_token)):
    return [p for p in db.paperLibrary.values() if p["userId"] == user["uid"]]

@app.post("/v1/papers")
def add_paper(payload: Dict[str, Any], user: Dict[str, Any] = Depends(verify_bearer_token)):
    title = payload.get("title", "").strip()
    if not title:
        raise HTTPException(status_code=400, detail="TITLE_REQUIRED")
    pid = f"paper-{uuid.uuid4().hex[:8]}"
    now = utc_now_iso()
    rec = {
        "id": pid,
        "userId": user["uid"],
        "title": title,
        "authors": payload.get("authors", []),
        "doi": payload.get("doi"),
        "url": payload.get("url"),
        "abstract": payload.get("abstract"),
        "year": payload.get("year"),
        "tags": payload.get("tags", []),
        "readingStatus": payload.get("readingStatus", "Want to read"),
        "privateNotes": payload.get("privateNotes"),
        "createdAt": now,
        "updatedAt": now
    }
    db.paperLibrary[pid] = rec
    db.save_to_disk()
    return rec

@app.delete("/v1/papers/{pid}")
def delete_paper(pid: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    rec = db.paperLibrary.get(pid)
    if not rec or rec["userId"] != user["uid"]:
        raise HTTPException(status_code=404, detail="PAPER_NOT_FOUND")
    del db.paperLibrary[pid]
    db.save_to_disk()
    return {"status": "deleted", "id": pid}

# ==================== My Network: Connections, Followers, Following (Section 6) ====================
@app.get("/v1/network/summary")
def get_network_summary(user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    conns = [c for c in db.connections.values() if (c.get("userA") == uid or c.get("userB") == uid) and c.get("status") == "ACTIVE"]
    followers = [f for f in db.follows.values() if f.get("targetId") == uid]
    following = [f for f in db.follows.values() if f.get("followerId") == uid]
    pending_received = [r for r in db.connectionRequests.values() if r.get("receiverId") == uid and r.get("status") == "PENDING"]
    return {
        "connectionsCount": len(conns),
        "followersCount": len(followers),
        "followingCount": len(following),
        "pendingReceivedCount": len(pending_received)
    }

@app.get("/v1/network/connections")
def get_my_connections(user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    conns = [c for c in db.connections.values() if (c.get("userA") == uid or c.get("userB") == uid) and c.get("status") == "ACTIVE"]
    result = []
    for c in conns:
        other_uid = c["userB"] if c["userA"] == uid else c["userA"]
        other_user = db.users.get(other_uid)
        if other_user:
            result.append({
                "connectionId": c["id"],
                "connectedAt": c.get("connectedAt", ""),
                "userId": other_user["uid"],
                "displayName": other_user["displayName"],
                "role": other_user["role"],
                "institution": other_user.get("institution", ""),
                "headline": other_user.get("headline", ""),
                "country": other_user.get("country", "")
            })
    return result

@app.get("/v1/network/followers")
def get_my_followers(user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    followers = [f for f in db.follows.values() if f.get("targetId") == uid]
    result = []
    for f in followers:
        u = db.users.get(f["followerId"])
        if u:
            is_following = f"{uid}_{u['uid']}" in db.follows
            result.append({
                "userId": u["uid"],
                "displayName": u["displayName"],
                "role": u["role"],
                "institution": u.get("institution", ""),
                "headline": u.get("headline", ""),
                "followedAt": f.get("createdAt", ""),
                "isFollowing": is_following
            })
    return result

@app.get("/v1/network/following")
def get_my_following(user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    following = [f for f in db.follows.values() if f.get("followerId") == uid]
    result = []
    for f in following:
        u = db.users.get(f["targetId"])
        if u:
            result.append({
                "userId": u["uid"],
                "displayName": u["displayName"],
                "role": u["role"],
                "institution": u.get("institution", ""),
                "headline": u.get("headline", ""),
                "followedAt": f.get("createdAt", ""),
                "isFollowing": True
            })
    return result

@app.get("/v1/network/requests/sent")
def get_sent_connection_requests(user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    reqs = [r for r in db.connectionRequests.values() if r.get("senderId") == uid and r.get("status") == "PENDING"]
    result = []
    for r in sorted(reqs, key=lambda x: x.get("createdAt", ""), reverse=True):
        rec_u = db.users.get(r["receiverId"], {})
        result.append({
            **r,
            "receiverName": rec_u.get("displayName", "Researcher"),
            "receiverRole": rec_u.get("role", ""),
            "receiverInstitution": rec_u.get("institution", "")
        })
    return result

@app.get("/v1/network/requests/received")
def get_received_connection_requests(user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    reqs = [r for r in db.connectionRequests.values() if r.get("receiverId") == uid and r.get("status") == "PENDING"]
    result = []
    for r in sorted(reqs, key=lambda x: x.get("createdAt", ""), reverse=True):
        snd_u = db.users.get(r["senderId"], {})
        result.append({
            **r,
            "senderName": snd_u.get("displayName", "Researcher"),
            "senderRole": snd_u.get("role", ""),
            "senderInstitution": snd_u.get("institution", "")
        })
    return result

@app.post("/v1/network/connect/{target_uid}")
def send_connection_request(target_uid: str, data: ConnectionRequestCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    sender_uid = user["uid"]
    if sender_uid == target_uid:
        raise HTTPException(status_code=400, detail="CANNOT_CONNECT_SELF")
    target_user = db.users.get(target_uid)
    if not target_user:
        raise HTTPException(status_code=404, detail="TARGET_USER_NOT_FOUND")
    users_sorted = sorted([sender_uid, target_uid])
    conn_id = f"conn-{users_sorted[0]}-{users_sorted[1]}"
    if conn_id in db.connections and db.connections[conn_id].get("status") == "ACTIVE":
        raise HTTPException(status_code=400, detail="ALREADY_CONNECTED")
    for r in db.connectionRequests.values():
        if r.get("senderId") == sender_uid and r.get("receiverId") == target_uid and r.get("status") == "PENDING":
            raise HTTPException(status_code=409, detail="DUPLICATE_PENDING_REQUEST")
    req_id = f"creq-{uuid.uuid4().hex[:8]}"
    now = utc_now_iso()
    sender_user = db.users.get(sender_uid, {})
    rec = {
        "id": req_id,
        "senderId": sender_uid,
        "senderName": sender_user.get("displayName", "Researcher"),
        "senderRole": sender_user.get("role", ""),
        "senderInstitution": sender_user.get("institution", ""),
        "receiverId": target_uid,
        "receiverName": target_user.get("displayName", "Researcher"),
        "receiverRole": target_user.get("role", ""),
        "receiverInstitution": target_user.get("institution", ""),
        "note": data.note,
        "status": "PENDING",
        "createdAt": now,
        "updatedAt": now
    }
    db.connectionRequests[req_id] = rec
    FirestoreTransactionEngine.atomic_create_notification(
        recipient_id=target_uid,
        notif_type="Connection",
        title="New Connection Request",
        body=f"{sender_user.get('displayName', 'A researcher')} wants to connect with you.",
        target_type="connectionRequest",
        target_id=req_id
    )
    db.save_to_disk()
    return rec

@app.post("/v1/network/connect/{request_id}/accept")
def accept_connection_request(request_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    try:
        return FirestoreTransactionEngine.atomic_accept_connection_request(request_id, user["uid"])
    except PermissionError:
        raise HTTPException(status_code=403, detail="PERMISSION_DENIED_NOT_RECEIVER")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/v1/network/connect/{request_id}/decline")
def decline_connection_request(request_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    req = db.connectionRequests.get(request_id)
    if not req:
        raise HTTPException(status_code=404, detail="REQUEST_NOT_FOUND")
    if req["receiverId"] != user["uid"]:
        raise HTTPException(status_code=403, detail="PERMISSION_DENIED")
    req["status"] = "DECLINED"
    req["updatedAt"] = utc_now_iso()
    db.save_to_disk()
    return {"status": "declined", "id": request_id}

@app.post("/v1/network/connect/{request_id}/withdraw")
def withdraw_connection_request(request_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    req = db.connectionRequests.get(request_id)
    if not req:
        raise HTTPException(status_code=404, detail="REQUEST_NOT_FOUND")
    if req["senderId"] != user["uid"]:
        raise HTTPException(status_code=403, detail="PERMISSION_DENIED")
    if req["status"] != "PENDING":
        raise HTTPException(status_code=400, detail="CANNOT_WITHDRAW_NON_PENDING")
    req["status"] = "WITHDRAWN"
    req["updatedAt"] = utc_now_iso()
    db.save_to_disk()
    return {"status": "withdrawn", "id": request_id}

@app.post("/v1/network/follow/{target_uid}")
def follow_user(target_uid: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    try:
        return FirestoreTransactionEngine.atomic_toggle_follow(user["uid"], target_uid)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.delete("/v1/network/follow/{target_uid}")
def unfollow_user(target_uid: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    key = f"{user['uid']}_{target_uid}"
    if key in db.follows:
        del db.follows[key]
        db.save_to_disk()
    return {"status": "unfollowed", "targetId": target_uid}

# ==================== Smart Matching & Semantic Recommendations (Section 7 & G) ====================
@app.get("/v1/matches/researchers")
def match_researchers(
    domainId: Optional[str] = None,
    topics: Optional[str] = None,
    mode: Optional[str] = "No preference",
    user: Dict[str, Any] = Depends(verify_bearer_token)
):
    query_topics = [t.strip() for t in topics.split(",")] if topics else []
    query_criteria = {
        "domainId": domainId,
        "topicTags": query_topics,
        "preferredCollaborationMode": mode
    }
    results = []
    for cand_uid, cand_user in db.users.items():
        if cand_uid == user["uid"] or cand_user.get("accountStatus") == "deleted":
            continue
        cand_interests = [i for i in db.researchInterests.values() if i["userId"] == cand_uid]
        score, reasons = score_researcher_match(query_criteria, cand_user, cand_interests)
        if score > 0:
            results.append({
                "userId": cand_uid,
                "displayName": cand_user["displayName"],
                "role": cand_user["role"],
                "institution": cand_user.get("institution"),
                "headline": cand_user.get("headline"),
                "score": score,
                "fitBand": "Strong" if score >= 65 else ("Possible" if score >= 35 else "Explore"),
                "reasons": reasons,
                "interests": cand_interests
            })
    results.sort(key=lambda x: x["score"], reverse=True)
    return results

@app.get("/v1/matches/mentors")
def match_mentors(
    topics: Optional[str] = None,
    helpType: Optional[str] = None,
    level: Optional[str] = "Beginner",
    user: Dict[str, Any] = Depends(verify_bearer_token)
):
    topic_list = [t.strip() for t in topics.split(",")] if topics else []
    needs = {"topics": topic_list, "helpType": helpType, "currentLevel": level}
    results = []
    for m_uid, m_prof in db.mentorProfiles.items():
        m_user = db.users.get(m_uid)
        if not m_user or m_user.get("accountStatus") == "deleted":
            continue
        score, reasons, eligible = score_mentor_match(needs, m_prof, m_user)
        if eligible and score > 0:
            results.append({
                "mentorId": m_uid,
                "displayName": m_user["displayName"],
                "headline": m_user.get("headline"),
                "institution": m_user.get("institution"),
                "expertise": m_prof.get("expertiseTags", []),
                "helpTypes": m_prof.get("helpTypes", []),
                "remainingCapacity": m_prof.get("maxCapacity", 3) - m_prof.get("activeMenteesCount", 0),
                "score": score,
                "reasons": reasons
            })
    results.sort(key=lambda x: x["score"], reverse=True)
    return results

# ==================== Mentor System (Section 8) ====================
@app.get("/v1/mentor/profile")
def get_my_mentor_profile(user: Dict[str, Any] = Depends(verify_bearer_token)):
    prof = db.mentorProfiles.get(user["uid"])
    if not prof:
        return {
            "userId": user["uid"],
            "mentorshipEnabled": False,
            "expertiseTags": [],
            "helpTypes": [],
            "menteeLevels": [],
            "formats": ["Remote"],
            "availability": "Available",
            "maxCapacity": 3,
            "activeMenteesCount": 0,
            "preferredFrequency": "Bi-weekly",
            "timezone": "UTC",
            "visibility": "Public to members"
        }
    return prof

@app.put("/v1/mentor/profile")
def update_my_mentor_profile(data: Dict[str, Any], user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    prof = db.mentorProfiles.get(uid, {"userId": uid, "activeMenteesCount": 0})
    for k in ["userId", "activeMenteesCount"]:
        data.pop(k, None)
    prof.update(data)
    db.mentorProfiles[uid] = prof
    db.save_to_disk()
    return prof

@app.post("/v1/mentor/questionnaire")
def save_mentor_questionnaire(data: MentorQuestionnaireInput, user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    rec = {
        "userId": uid,
        "answers": data.dict(),
        "updatedAt": utc_now_iso()
    }
    db.mentorQuestionnaires[uid] = rec
    db.save_to_disk()
    return {"status": "saved", "questionnaire": rec}

@app.get("/v1/mentor/questionnaire")
def get_mentor_questionnaire(user: Dict[str, Any] = Depends(verify_bearer_token)):
    return db.mentorQuestionnaires.get(user["uid"], {"userId": user["uid"], "answers": {}})

@app.post("/v1/mentor/requests")
def send_mentor_request(data: MentorRequestCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    mentee_id = user["uid"]
    mentor_id = data.mentorId
    if mentee_id == mentor_id:
        raise HTTPException(status_code=400, detail="CANNOT_REQUEST_SELF_MENTORSHIP")
    m_prof = db.mentorProfiles.get(mentor_id)
    if not m_prof or not m_prof.get("mentorshipEnabled", False) or m_prof.get("availability") != "Available":
        raise HTTPException(status_code=400, detail="MENTOR_NOT_AVAILABLE")
    if m_prof.get("activeMenteesCount", 0) >= m_prof.get("maxCapacity", 3):
        raise HTTPException(status_code=400, detail="MENTOR_CAPACITY_FULL")
    for r in db.mentorRequests.values():
        if r.get("menteeId") == mentee_id and r.get("mentorId") == mentor_id and r.get("status") == "Pending":
            raise HTTPException(status_code=409, detail="DUPLICATE_PENDING_MENTOR_REQUEST")
    m_req_id = f"mreq-{uuid.uuid4().hex[:8]}"
    now = utc_now_iso()
    mentee_user = db.users.get(mentee_id, {})
    mentor_user = db.users.get(mentor_id, {})
    rec = {
        "id": m_req_id,
        "menteeId": mentee_id,
        "menteeName": mentee_user.get("displayName", "Mentee"),
        "menteeRole": mentee_user.get("role", ""),
        "mentorId": mentor_id,
        "mentorName": mentor_user.get("displayName", "Mentor"),
        "interestId": data.interestId,
        "helpType": data.helpType,
        "context": data.context,
        "format": data.format,
        "frequency": data.frequency,
        "timezone": data.timezone,
        "questions": data.questions,
        "status": "Pending",
        "createdAt": now,
        "updatedAt": now
    }
    db.mentorRequests[m_req_id] = rec
    FirestoreTransactionEngine.atomic_create_notification(
        recipient_id=mentor_id,
        notif_type="Mentorship",
        title="New Mentorship Request! 🎓",
        body=f"{mentee_user.get('displayName', 'A researcher')} requested your mentorship in {data.helpType}.",
        target_type="mentorRequest",
        target_id=m_req_id
    )
    db.save_to_disk()
    return rec

@app.get("/v1/mentor/requests/sent")
def list_sent_mentor_requests(user: Dict[str, Any] = Depends(verify_bearer_token)):
    reqs = [r for r in db.mentorRequests.values() if r.get("menteeId") == user["uid"]]
    return sorted(reqs, key=lambda x: x.get("createdAt", ""), reverse=True)

@app.get("/v1/mentor/requests/received")
def list_received_mentor_requests(user: Dict[str, Any] = Depends(verify_bearer_token)):
    reqs = [r for r in db.mentorRequests.values() if r.get("mentorId") == user["uid"]]
    return sorted(reqs, key=lambda x: x.get("createdAt", ""), reverse=True)

@app.post("/v1/mentor/requests/{req_id}/decision")
def decide_mentor_request(req_id: str, data: MentorDecisionRequest, user: Dict[str, Any] = Depends(verify_bearer_token)):
    req = db.mentorRequests.get(req_id)
    if not req:
        raise HTTPException(status_code=404, detail="REQUEST_NOT_FOUND")
    if req["mentorId"] != user["uid"]:
        raise HTTPException(status_code=403, detail="PERMISSION_DENIED")
    decision = data.status.upper()
    if decision not in ["ACCEPTED", "DECLINED", "NEEDS_INFO"]:
        raise HTTPException(status_code=400, detail="INVALID_DECISION_STATUS")
    if decision == "ACCEPTED":
        try:
            FirestoreTransactionEngine.atomic_reserve_mentor_slot(user["uid"], req["menteeId"])
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        req["status"] = "Accepted"
        req["decidedAt"] = utc_now_iso()

        # Create (or reuse) the private one-to-one mentorship conversation.
        # Both mentor and mentee will see it in their Messages list.
        participants = {user["uid"], req["menteeId"]}
        mentorship_conversation = next(
            (c for c in db.conversations.values()
             if set(c.get("participants", [])) == participants),
            None,
        )
        if mentorship_conversation is None:
            now = utc_now_iso()
            conv_id = f"conv-{uuid.uuid4().hex[:8]}"
            mentorship_conversation = {
                "id": conv_id,
                "participants": [user["uid"], req["menteeId"]],
                "conversationType": "mentorship",
                "mentorRequestId": req_id,
                "lastMessage": "Your mentorship conversation is ready. Say hello!",
                "lastMessageTime": now,
                "createdAt": now,
            }
            db.conversations[conv_id] = mentorship_conversation
        req["conversationId"] = mentorship_conversation["id"]

        FirestoreTransactionEngine.atomic_create_notification(
            recipient_id=req["menteeId"],
            notif_type="Mentorship",
            title="Mentorship Request Accepted! 🎉",
            body=f"{req.get('mentorName', 'Your mentor')} accepted your mentorship request.",
            target_type="mentorship",
            target_id=req_id
        )
    elif decision == "DECLINED":
        req["status"] = "Declined"
        req["declineReason"] = data.reason
        req["decidedAt"] = utc_now_iso()
        FirestoreTransactionEngine.atomic_create_notification(
            recipient_id=req["menteeId"],
            notif_type="Mentorship",
            title="Mentorship Request Update",
            body=f"{req.get('mentorName', 'Your mentor')} declined your mentorship request.",
            target_type="mentorRequest",
            target_id=req_id
        )
    elif decision == "NEEDS_INFO":
        req["status"] = "Clarification"
        req["clarificationNote"] = data.reason
        FirestoreTransactionEngine.atomic_create_notification(
            recipient_id=req["menteeId"],
            notif_type="Mentorship",
            title="More Information Requested",
            body=f"{req.get('mentorName', 'Your mentor')} requested more information about your mentorship request.",
            target_type="mentorRequest",
            target_id=req_id
        )
    req["updatedAt"] = utc_now_iso()
    db.save_to_disk()
    return req

@app.post("/v1/mentor/requests/{req_id}/withdraw")
def withdraw_mentor_request(req_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    req = db.mentorRequests.get(req_id)
    if not req:
        raise HTTPException(status_code=404, detail="REQUEST_NOT_FOUND")
    if req["menteeId"] != user["uid"]:
        raise HTTPException(status_code=403, detail="PERMISSION_DENIED")
    if req["status"] != "Pending":
        raise HTTPException(status_code=400, detail="CANNOT_WITHDRAW_NON_PENDING")
    req["status"] = "Withdrawn"
    req["updatedAt"] = utc_now_iso()
    db.save_to_disk()
    return {"status": "withdrawn", "id": req_id}

# ==================== Team Requests & Collaboration (Section 7.2 & 9) ====================
@app.get("/v1/team-requests")
def list_team_requests(domain: Optional[str] = None):
    reqs = [r for r in db.teamRequests.values() if r.get("visibility") == "Discoverable"]
    if domain:
        reqs = [r for r in reqs if r.get("primaryDomain") == domain or domain in r.get("relatedDomains", [])]
    return reqs

@app.post("/v1/team-requests")
def create_team_request(data: TeamRequestCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    req_id = f"req-{uuid.uuid4().hex[:8]}"
    now = utc_now_iso()
    rec = {
        "id": req_id,
        "ownerId": user["uid"],
        "remainingCapacity": data.membersNeeded,
        "status": "Open",
        "createdAt": now,
        "updatedAt": now,
        **data.dict()
    }
    db.teamRequests[req_id] = rec
    db.save_to_disk()
    return rec

@app.post("/v1/team-requests/{req_id}/apply")
def apply_to_team_request(req_id: str, data: TeamApplicationCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    team_req = db.teamRequests.get(req_id)
    if not team_req:
        raise HTTPException(status_code=404, detail="REQUEST_NOT_FOUND")
    if team_req["status"] != "Open" or team_req["remainingCapacity"] <= 0:
        raise HTTPException(status_code=400, detail="TEAM_REQUEST_NOT_OPEN")
    if team_req["ownerId"] == user["uid"]:
        raise HTTPException(status_code=400, detail="CANNOT_APPLY_TO_OWN_REQUEST")

    for app in db.teamApplications.values():
        if app["requestId"] == req_id and app["applicantId"] == user["uid"]:
            raise HTTPException(status_code=409, detail="DUPLICATE_APPLICATION")

    app_id = f"app-{uuid.uuid4().hex[:8]}"
    u_rec = db.users.get(user["uid"], {})
    rec = {
        "id": app_id,
        "requestId": req_id,
        "applicantId": user["uid"],
        "applicantName": u_rec.get("displayName", "Applicant"),
        "applicantRole": u_rec.get("role", "Researcher"),
        "applicantInstitution": u_rec.get("institution", ""),
        "projectTitle": team_req.get("title", ""),
        "message": data.message,
        "skills": data.skills,
        "answers": data.answers,
        "resumeUrl": data.resumeUrl,
        "resumeStoragePath": data.resumeStoragePath,
        "resumeFileName": data.resumeFileName,
        "status": "Pending",
        "createdAt": utc_now_iso(),
        "decidedAt": None
    }
    db.teamApplications[app_id] = rec
    FirestoreTransactionEngine.atomic_create_notification(
        recipient_id=team_req["ownerId"],
        notif_type="Team",
        title="New Team Application",
        body=f"{u_rec.get('displayName', 'A researcher')} applied to '{team_req['title']}'.",
        target_type="teamApplication",
        target_id=app_id,
        idempotency_key=f"team_apply_{req_id}_{user['uid']}"
    )
    db.save_to_disk()
    return rec

@app.get("/v1/team-applications/me")
def list_my_team_applications(user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    apps = [a for a in db.teamApplications.values() if a.get("applicantId") == uid]
    result = []
    for a in apps:
        req = db.teamRequests.get(a["requestId"], {})
        result.append({
            **a,
            "projectTitle": req.get("title", "Research Project"),
            "primaryDomain": req.get("primaryDomain", ""),
            "projectStage": req.get("projectStage", ""),
        })
    return sorted(result, key=lambda x: x.get("createdAt", ""), reverse=True)

@app.get("/v1/team-requests/{req_id}/applications")
def list_team_request_applications(req_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    req = db.teamRequests.get(req_id)
    if not req:
        raise HTTPException(status_code=404, detail="REQUEST_NOT_FOUND")
    if req["ownerId"] != user["uid"] and not user.get("isAdmin", False):
        raise HTTPException(status_code=403, detail="OWNER_ONLY_ACCESS")
    apps = [a for a in db.teamApplications.values() if a.get("requestId") == req_id]
    result = []
    for a in apps:
        app_u = db.users.get(a["applicantId"], {})
        result.append({
            **a,
            "applicantName": app_u.get("displayName", "Applicant"),
            "applicantRole": app_u.get("role", ""),
            "applicantInstitution": app_u.get("institution", "")
        })
    return result

@app.post("/v1/team-applications/{app_id}/decision")
def decide_team_application(app_id: str, decision: Dict[str, str], user: Dict[str, Any] = Depends(verify_bearer_token)):
    new_status = decision.get("status")
    if new_status == "Accepted":
        try:
            return FirestoreTransactionEngine.atomic_accept_team_application(app_id, user["uid"])
        except ValueError as ve:
            raise HTTPException(status_code=409, detail=str(ve))
        except PermissionError as pe:
            raise HTTPException(status_code=403, detail=str(pe))

    app_rec = db.teamApplications.get(app_id)
    if not app_rec:
        raise HTTPException(status_code=404, detail="APPLICATION_NOT_FOUND")
    team_req = db.teamRequests.get(app_rec["requestId"])
    if not team_req:
        raise HTTPException(status_code=404, detail="REQUEST_NOT_FOUND")
    if team_req["ownerId"] != user["uid"] and not user.get("isAdmin", False):
        raise HTTPException(status_code=403, detail="OWNER_ONLY_ACCESS")
    if new_status != "Declined":
        raise HTTPException(status_code=400, detail="INVALID_APPLICATION_DECISION")

    app_rec["status"] = "Declined"
    app_rec["decidedAt"] = utc_now_iso()
    FirestoreTransactionEngine.atomic_create_notification(
        recipient_id=app_rec["applicantId"],
        notif_type="Team",
        title="Team Application Update",
        body=f"Your application to '{team_req['title']}' was declined.",
        target_type="teamApplication",
        target_id=app_id
    )
    db.save_to_disk()
    return {"status": "success", "application": app_rec}

# ==================== Collaboration Workspace & Tasks (Section 9) ====================
@app.get("/v1/projects")
def list_my_projects(user: Dict[str, Any] = Depends(verify_bearer_token)):
    return [p for p in db.projects.values() if user["uid"] in p.get("memberIds", []) or p["ownerId"] == user["uid"]]

@app.get("/v1/projects/{proj_id}")
def get_project_details(proj_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    proj = db.projects.get(proj_id)
    if not proj or (user["uid"] not in proj.get("memberIds", []) and proj["ownerId"] != user["uid"] and not user.get("isAdmin")):
        raise HTTPException(status_code=403, detail="PERMISSION_DENIED_NOT_PROJECT_MEMBER")
    tasks = [t for t in db.tasks.values() if t.get("projectId") == proj_id]
    milestones = [m for m in db.milestones.values() if m.get("projectId") == proj_id]
    return {"project": proj, "tasks": tasks, "milestones": milestones}

@app.get("/v1/projects/{proj_id}/tasks")
def list_project_tasks(proj_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    proj = db.projects.get(proj_id)
    if not proj:
        raise HTTPException(status_code=404, detail="PROJECT_NOT_FOUND")
    if user["uid"] not in proj.get("memberIds", []) and not user.get("isAdmin", False):
        raise HTTPException(status_code=403, detail="MEMBER_ONLY_ACCESS")
    return [t for t in db.tasks.values() if t.get("projectId") == proj_id]

@app.post("/v1/projects/{proj_id}/tasks")
def add_project_task(proj_id: str, data: ProjectTaskCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    proj = db.projects.get(proj_id)
    if not proj:
        raise HTTPException(status_code=404, detail="PROJECT_NOT_FOUND")
    if user["uid"] not in proj.get("memberIds", []) and proj["ownerId"] != user["uid"] and not user.get("isAdmin", False):
        raise HTTPException(status_code=403, detail="MEMBER_ONLY_ACCESS")
    tid = f"task-{uuid.uuid4().hex[:8]}"
    assignee_id = data.assigneeId or user["uid"]
    project_members = set(proj.get("memberIds", []))
    project_members.add(proj["ownerId"])
    if assignee_id not in project_members:
        raise HTTPException(status_code=400, detail="ASSIGNEE_NOT_PROJECT_MEMBER")
    u_rec = db.users.get(assignee_id, {})
    rec = {
        "id": tid,
        "projectId": proj_id,
        "title": data.title,
        "description": data.description,
        "assigneeId": assignee_id,
        "assigneeName": u_rec.get("displayName", "Member"),
        "priority": data.priority,
        "dueDate": data.dueDate,
        "status": "Not started",
        "createdAt": utc_now_iso()
    }
    db.tasks[tid] = rec
    if assignee_id != user["uid"]:
        actor = db.users.get(user["uid"], {})
        FirestoreTransactionEngine.atomic_create_notification(
            recipient_id=assignee_id,
            notif_type="Team",
            title="New Project Task",
            body=f"{actor.get('displayName', 'A project member')} assigned you '{data.title}'.",
            target_type="project",
            target_id=proj_id
        )
    db.save_to_disk()
    return rec

@app.put("/v1/projects/{proj_id}/tasks/{task_id}")
def update_project_task(proj_id: str, task_id: str, updates: Dict[str, Any], user: Dict[str, Any] = Depends(verify_bearer_token)):
    task = db.tasks.get(task_id)
    if not task or task.get("projectId") != proj_id:
        raise HTTPException(status_code=404, detail="TASK_NOT_FOUND")
    project = db.projects.get(proj_id)
    if not project:
        raise HTTPException(status_code=404, detail="PROJECT_NOT_FOUND")
    if user["uid"] not in project.get("memberIds", []) and project["ownerId"] != user["uid"] and not user.get("isAdmin", False):
        raise HTTPException(status_code=403, detail="MEMBER_ONLY_ACCESS")
    if "projectId" in updates and updates["projectId"] != proj_id:
        raise HTTPException(status_code=400, detail="PROJECT_ID_CANNOT_BE_CHANGED")
    if "id" in updates and updates["id"] != task_id:
        raise HTTPException(status_code=400, detail="TASK_ID_CANNOT_BE_CHANGED")
    if "assigneeId" in updates and updates["assigneeId"] is not None:
        project_members = set(project.get("memberIds", []))
        project_members.add(project["ownerId"])
        if updates["assigneeId"] not in project_members:
            raise HTTPException(status_code=400, detail="ASSIGNEE_NOT_PROJECT_MEMBER")
    task.update(updates)
    task["updatedAt"] = utc_now_iso()
    assignee_id = task.get("assigneeId")
    if assignee_id and assignee_id != user["uid"]:
        FirestoreTransactionEngine.atomic_create_notification(
            recipient_id=assignee_id,
            notif_type="Team",
            title="Project Task Updated",
            body=f"'{task.get('title', 'A project task')}' was updated.",
            target_type="project",
            target_id=proj_id
        )
    db.save_to_disk()
    return task

@app.get("/v1/projects/{proj_id}/milestones")
def list_project_milestones(proj_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    proj = db.projects.get(proj_id)
    if not proj:
        raise HTTPException(status_code=404, detail="PROJECT_NOT_FOUND")
    if user["uid"] not in proj.get("memberIds", []) and not user.get("isAdmin", False):
        raise HTTPException(status_code=403, detail="MEMBER_ONLY_ACCESS")
    return [m for m in db.milestones.values() if m.get("projectId") == proj_id]

@app.post("/v1/projects/{proj_id}/milestones")
def add_project_milestone(proj_id: str, data: ProjectMilestoneCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    proj = db.projects.get(proj_id)
    if not proj:
        raise HTTPException(status_code=404, detail="PROJECT_NOT_FOUND")
    if user["uid"] not in proj.get("memberIds", []) and not user.get("isAdmin", False):
        raise HTTPException(status_code=403, detail="MEMBER_ONLY_ACCESS")
    mid = f"mile-{uuid.uuid4().hex[:8]}"
    rec = {
        "id": mid,
        "projectId": proj_id,
        "title": data.title,
        "description": data.description,
        "dueDate": data.dueDate,
        "status": "Pending",
        "createdAt": utc_now_iso()
    }
    db.milestones[mid] = rec
    member_ids = set(proj.get("memberIds", []))
    member_ids.add(proj["ownerId"])
    actor = db.users.get(user["uid"], {})
    for member_id in member_ids - {user["uid"]}:
        FirestoreTransactionEngine.atomic_create_notification(
            recipient_id=member_id,
            notif_type="Team",
            title="Project Milestone Added",
            body=f"{actor.get('displayName', 'A project member')} added '{data.title}'.",
            target_type="project",
            target_id=proj_id
        )
    db.save_to_disk()
    return rec

# ==================== Research Groups (Section 10) ====================
@app.get("/v1/groups")
def list_groups(domain: Optional[str] = None):
    groups = list(db.groups.values())
    if domain:
        groups = [g for g in groups if g.get("primaryDomain", "").lower() == domain.lower()]
    return groups

@app.get("/v1/groups/my")
def list_my_groups(user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    joined_ids = {
        m["groupId"] for m in db.groupMembers.values()
        if m.get("userId") == uid and m.get("status") == "ACTIVE"
    }
    return [g for g in db.groups.values() if g["id"] in joined_ids]

@app.get("/v1/groups/recommended")
def list_recommended_groups(user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    user_ints = [i for i in db.researchInterests.values() if i.get("userId") == uid]
    user_topics = set()
    user_domains = set()
    for i in user_ints:
        user_domains.add(i.get("domainId", "").lower())
        for t in i.get("topicTags", []):
            user_topics.add(t.lower())

    joined_ids = {
        m["groupId"] for m in db.groupMembers.values()
        if m.get("userId") == uid and m.get("status") == "ACTIVE"
    }

    results = []
    for g in db.groups.values():
        if g["id"] in joined_ids:
            continue
        g_topics = set(t.lower() for t in g.get("topics", []))
        overlap = user_topics.intersection(g_topics)
        domain_match = g.get("primaryDomain", "").lower() in user_domains
        score = (len(overlap) * 20.0) + (30.0 if domain_match else 0.0)
        reasons = [f"Matches your topic: {t.title()}" for t in list(overlap)[:2]]
        if domain_match:
            reasons.append("Matches your research domain")
        if not reasons:
            reasons.append("Broad academic interest")
        results.append({
            **g,
            "recommendationScore": min(100.0, score + 30.0 if (domain_match or overlap) else 15.0),
            "matchReasons": reasons
        })
    results.sort(key=lambda x: x["recommendationScore"], reverse=True)
    return results

@app.post("/v1/groups")
def create_group(data: GroupCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    gid = f"grp-{uuid.uuid4().hex[:8]}"
    now = utc_now_iso()
    rec = {
        "id": gid,
        "ownerId": user["uid"],
        "title": data.title,
        "description": data.description,
        "primaryDomain": data.primaryDomain,
        "topics": data.topics,
        "purpose": data.purpose,
        "membershipMode": data.membershipMode,
        "visibility": data.visibility,
        "rules": data.rules,
        "moderators": [user["uid"]],
        "memberCount": 1,
        "status": "Active",
        "createdAt": now
    }
    db.groups[gid] = rec
    db.groupMembers[f"{gid}_{user['uid']}"] = {
        "id": f"{gid}_{user['uid']}",
        "groupId": gid,
        "userId": user["uid"],
        "role": "Owner",
        "status": "ACTIVE",
        "joinedAt": now
    }
    db.save_to_disk()
    return rec

@app.post("/v1/groups/{group_id}/join")
def join_group(group_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    grp = db.groups.get(group_id)
    if not grp:
        raise HTTPException(status_code=404, detail="GROUP_NOT_FOUND")
    uid = user["uid"]
    key = f"{group_id}_{uid}"
    if key in db.groupMembers and db.groupMembers[key].get("status") == "ACTIVE":
        return {"status": "already_member", "membership": db.groupMembers[key]}
    now = utc_now_iso()
    mode = grp.get("membershipMode", "Open")
    if mode == "Open":
        db.groupMembers[key] = {
            "id": key,
            "groupId": group_id,
            "userId": uid,
            "role": "Member",
            "status": "ACTIVE",
            "joinedAt": now
        }
        grp["memberCount"] = grp.get("memberCount", 1) + 1
        actor = db.users.get(uid, {})
        group_managers = set(grp.get("moderators", []))
        group_managers.add(grp["ownerId"])
        for manager_id in group_managers - {uid}:
            FirestoreTransactionEngine.atomic_create_notification(
                recipient_id=manager_id,
                notif_type="Group",
                title="New Group Member",
                body=f"{actor.get('displayName', 'A researcher')} joined '{grp['title']}'.",
                target_type="group",
                target_id=group_id
            )
        db.save_to_disk()
        return {"status": "joined", "role": "Member"}
    else:
        db.groupMembers[key] = {
            "id": key,
            "groupId": group_id,
            "userId": uid,
            "role": "Applicant",
            "status": "PENDING",
            "appliedAt": now
        }
        FirestoreTransactionEngine.atomic_create_notification(
            recipient_id=grp["ownerId"],
            notif_type="Group",
            title="Group Join Request",
            body=f"A researcher requested to join '{grp['title']}'.",
            target_type="group",
            target_id=group_id
        )
        db.save_to_disk()
        return {"status": "requested", "role": "Applicant"}

@app.post("/v1/groups/{group_id}/leave")
def leave_group(group_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    grp = db.groups.get(group_id)
    if not grp:
        raise HTTPException(status_code=404, detail="GROUP_NOT_FOUND")
    uid = user["uid"]
    key = f"{group_id}_{uid}"
    if key in db.groupMembers:
        del db.groupMembers[key]
        grp["memberCount"] = max(0, grp.get("memberCount", 1) - 1)
        db.save_to_disk()
        return {"status": "left", "groupId": group_id}
    return {"status": "not_member", "groupId": group_id}

# ==================== Academic Community Feed (Section 11) ====================
@app.get("/v1/feed")
def list_feed(domain: Optional[str] = None, post_type: Optional[str] = None):
    posts = list(db.posts.values())
    if domain:
        posts = [p for p in posts if domain.lower() in [d.lower() for d in p.get("domainTags", [])]]
    if post_type:
        posts = [p for p in posts if p.get("postType", "").lower() == post_type.lower()]
    return sorted(posts, key=lambda x: x.get("createdAt", ""), reverse=True)

@app.post("/v1/feed/posts")
def create_feed_post(data: FeedPostCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    pid = f"post-{uuid.uuid4().hex[:8]}"
    u_rec = db.users.get(user["uid"], {})
    rec = {
        "id": pid,
        "authorId": user["uid"],
        "authorName": u_rec.get("displayName", "Scholar"),
        "authorHeadline": u_rec.get("headline", u_rec.get("role", "Researcher")),
        "reactionCount": 0,
        "commentCount": 0,
        "createdAt": utc_now_iso(),
        **data.dict()
    }
    db.posts[pid] = rec
    db.save_to_disk()
    return rec

@app.delete("/v1/feed/posts/{post_id}")
def delete_feed_post(post_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    post = db.posts.get(post_id)
    if not post:
        raise HTTPException(status_code=404, detail="POST_NOT_FOUND")
    if post["authorId"] != user["uid"] and not user.get("isAdmin", False):
        raise HTTPException(status_code=403, detail="PERMISSION_DENIED")
    del db.posts[post_id]
    db.save_to_disk()
    return {"status": "deleted", "id": post_id}

@app.post("/v1/feed/posts/{post_id}/react")
def react_to_post(post_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    post = db.posts.get(post_id)
    if not post:
        raise HTTPException(status_code=404, detail="POST_NOT_FOUND")
    key = f"{user['uid']}_{post_id}"
    if key in db.postReactions:
        del db.postReactions[key]
        post["reactionCount"] = max(0, post.get("reactionCount", 1) - 1)
        reacted = False
    else:
        db.postReactions[key] = {"id": key, "userId": user["uid"], "postId": post_id, "createdAt": utc_now_iso()}
        post["reactionCount"] = post.get("reactionCount", 0) + 1
        reacted = True
    db.save_to_disk()
    return {"status": "success", "reactionCount": post["reactionCount"], "hasReacted": reacted}

@app.get("/v1/feed/posts/{post_id}/comments")
def list_post_comments(post_id: str):
    comments = [c for c in db.comments.values() if c.get("postId") == post_id]
    return sorted(comments, key=lambda x: x.get("createdAt", ""))

@app.post("/v1/feed/posts/{post_id}/comments")
def add_post_comment(post_id: str, data: CommentCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    post = db.posts.get(post_id)
    if not post:
        raise HTTPException(status_code=404, detail="POST_NOT_FOUND")
    cid = f"comment-{uuid.uuid4().hex[:8]}"
    u_rec = db.users.get(user["uid"], {})
    rec = {
        "id": cid,
        "postId": post_id,
        "authorId": user["uid"],
        "authorName": u_rec.get("displayName", "Scholar"),
        "authorRole": u_rec.get("role", "Researcher"),
        "text": data.text,
        "createdAt": utc_now_iso()
    }
    db.comments[cid] = rec
    post["commentCount"] = post.get("commentCount", 0) + 1
    if post["authorId"] != user["uid"]:
        FirestoreTransactionEngine.atomic_create_notification(
            recipient_id=post["authorId"],
            notif_type="Social",
            title="New Comment on Your Post",
            body=f"{u_rec.get('displayName', 'Someone')} commented on your post.",
            target_type="post",
            target_id=post_id
        )
    db.save_to_disk()
    return rec

# ==================== Direct Messaging (Section 12) ====================
@app.get("/v1/messages/conversations")
def list_my_conversations(user: Dict[str, Any] = Depends(verify_bearer_token)):
    uid = user["uid"]
    convs = [c for c in db.conversations.values() if uid in c.get("participants", [])]
    result = []
    for c in sorted(convs, key=lambda x: x.get("lastMessageTime", ""), reverse=True):
        other_uid = next((p for p in c["participants"] if p != uid), uid)
        other_u = db.users.get(other_uid, {})
        unread = len([m for m in db.messages.values() if m.get("conversationId") == c["id"] and m.get("senderId") != uid and not m.get("read", False)])
        result.append({
            "id": c["id"],
            "participants": c["participants"],
            "otherUserId": other_uid,
            "otherUserName": other_u.get("displayName", "Academic Peer"),
            "otherUserRole": other_u.get("role", ""),
            "otherUserInstitution": other_u.get("institution", ""),
            "lastMessage": c.get("lastMessage", "Conversation started"),
            "lastMessageTime": c.get("lastMessageTime", c.get("createdAt", "")),
            "unreadCount": unread
        })
    return result

@app.post("/v1/messages/start")
def start_conversation(data: Dict[str, str], user: Dict[str, Any] = Depends(verify_bearer_token)):
    sender_uid = user["uid"]
    target_uid = data.get("targetUserId")
    if not target_uid or sender_uid == target_uid:
        raise HTTPException(status_code=400, detail="INVALID_TARGET_USER")

    # Direct messages are allowed only for active connections or accepted
    # mentorship pairs. Do not create arbitrary private chats.
    users_sorted = sorted([sender_uid, target_uid])
    connection_id = f"conn-{users_sorted[0]}-{users_sorted[1]}"
    is_connected = (
        db.connections.get(connection_id, {}).get("status") == "ACTIVE"
    )
    is_accepted_mentorship = any(
        r.get("status", "").lower() == "accepted"
        and {r.get("mentorId"), r.get("menteeId")} == {sender_uid, target_uid}
        for r in db.mentorRequests.values()
    )
    if not (is_connected or is_accepted_mentorship):
        raise HTTPException(
            status_code=403,
            detail="MESSAGING_REQUIRES_ACCEPTED_CONNECTION_OR_MENTORSHIP",
        )

    for c in db.conversations.values():
        if set(c.get("participants", [])) == {sender_uid, target_uid}:
            return c
    conv_id = f"conv-{uuid.uuid4().hex[:8]}"
    now = utc_now_iso()
    conv = {
        "id": conv_id,
        "participants": [sender_uid, target_uid],
        "lastMessage": "Conversation started",
        "lastMessageTime": now,
        "createdAt": now
    }
    db.conversations[conv_id] = conv
    db.save_to_disk()
    return conv

@app.get("/v1/messages/conversations/{conv_id}/messages")
def get_conversation_messages(conv_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    conv = db.conversations.get(conv_id)
    if not conv or user["uid"] not in conv.get("participants", []):
        raise HTTPException(status_code=403, detail="NOT_A_PARTICIPANT")
    msgs = [m for m in db.messages.values() if m.get("conversationId") == conv_id]
    for m in msgs:
        if m.get("senderId") != user["uid"]:
            m["read"] = True
    db.save_to_disk()
    return sorted(msgs, key=lambda x: x.get("createdAt", ""))

@app.post("/v1/messages/conversations/{conv_id}/messages")
def send_message_in_conversation(conv_id: str, data: SendMessageRequest, user: Dict[str, Any] = Depends(verify_bearer_token)):
    conv = db.conversations.get(conv_id)
    if not conv or user["uid"] not in conv.get("participants", []):
        raise HTTPException(status_code=403, detail="NOT_A_PARTICIPANT")
    mid = f"msg-{uuid.uuid4().hex[:8]}"
    now = utc_now_iso()
    u_rec = db.users.get(user["uid"], {})
    rec = {
        "id": mid,
        "conversationId": conv_id,
        "senderId": user["uid"],
        "senderName": u_rec.get("displayName", "Me"),
        "text": data.text,
        "attachmentUrl": data.attachmentUrl,
        "read": False,
        "createdAt": now
    }
    db.messages[mid] = rec
    conv["lastMessage"] = data.text
    conv["lastMessageTime"] = now
    other_uid = next((p for p in conv["participants"] if p != user["uid"]), None)
    if other_uid:
        FirestoreTransactionEngine.atomic_create_notification(
            recipient_id=other_uid,
            notif_type="Message",
            title=f"Message from {u_rec.get('displayName', 'Peer')}",
            body=data.text[:100],
            target_type="conversation",
            target_id=conv_id
        )
    db.save_to_disk()
    return rec

# ==================== Well-Being (Section 10 - Strictly Confidential Mood) ====================
@app.get("/v1/wellbeing/moods")
def list_my_mood_entries(user: Dict[str, Any] = Depends(verify_bearer_token)):
    return [m for m in db.moodEntries.values() if m["userId"] == user["uid"]]

@app.post("/v1/wellbeing/moods")
def record_mood_checkin(data: MoodCheckinCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    mid = f"mood-{uuid.uuid4().hex[:8]}"
    rec = {
        "id": mid,
        "userId": user["uid"],
        "createdAt": utc_now_iso(),
        **data.dict()
    }
    db.moodEntries[mid] = rec
    db.save_to_disk()
    return rec

@app.delete("/v1/wellbeing/moods/{mid}")
def delete_mood_entry(mid: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    rec = db.moodEntries.get(mid)
    if not rec or rec["userId"] != user["uid"]:
        raise HTTPException(status_code=404, detail="ENTRY_NOT_FOUND")
    del db.moodEntries[mid]
    db.save_to_disk()
    return {"status": "deleted", "id": mid}

@app.get("/v1/wellbeing/support-posts")
def list_support_posts(user: Dict[str, Any] = Depends(verify_bearer_token)):
    posts = list(db.supportPosts.values())
    is_admin = user.get("isAdmin", False)
    clean_posts = []
    for p in posts:
        item = dict(p)
        if item.get("displayMode") == "Hide identity from ordinary members" and not is_admin and item.get("authorId") != user["uid"]:
            item["authorDisplayName"] = "Anonymous Member"
        clean_posts.append(item)
    return clean_posts

@app.post("/v1/wellbeing/support-posts")
def create_support_post(data: PeerSupportPostCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    if not data.safetyAcknowledged:
        raise HTTPException(status_code=400, detail="SAFETY_ACKNOWLEDGEMENT_REQUIRED")
    sp_id = f"sp-{uuid.uuid4().hex[:8]}"
    u_rec = db.users.get(user["uid"], {})
    rec = {
        "id": sp_id,
        "authorId": user["uid"],
        "authorDisplayName": u_rec.get("displayName", "Member"),
        "createdAt": utc_now_iso(),
        **data.dict()
    }
    db.supportPosts[sp_id] = rec
    db.save_to_disk()
    return rec

@app.get("/v1/wellbeing/professional-support")
def get_professional_support(query: Optional[str] = None):
    """
    Section 4.3: Professional Support & Well-being Discovery.
    Returns administrator-verified mental health professionals and counsellors.
    """
    resources = [
        {
            "id": "prof-01",
            "name": "University Counselling & Psychological Services",
            "category": "Counsellor",
            "institutionOrOrganization": "Academic Psychological Network",
            "qualifications": "Licensed Clinical Psychologist, Ph.D.",
            "description": "Specialized support for doctoral researchers experiencing academic burnout, imposter syndrome, and research stress.",
            "verifiedBy": "ResWave Clinical Review Board",
            "lastVerifiedDate": "2026-11-15",
            "contactUrlOrEmail": "https://caps.academicsupport.org",
            "availabilityNote": "Online sessions available by appointment"
        },
        {
            "id": "prof-02",
            "name": "Graduate Student Mental Health Initiative",
            "category": "Mental Health Professional",
            "institutionOrOrganization": "Higher Ed Wellness Consortium",
            "qualifications": "Licensed Mental Health Counselor (LMHC)",
            "description": "Evidence-based cognitive coping strategies for postgraduate thesis defense anxiety and advisor-student conflict.",
            "verifiedBy": "ResWave Clinical Review Board",
            "lastVerifiedDate": "2026-11-10",
            "contactUrlOrEmail": "https://wellness.higheredhealth.org",
            "availabilityNote": "Weekly virtual listening circles and 1-on-1 consultations"
        }
    ]
    if query:
        q = query.lower()
        resources = [r for r in resources if q in r["name"].lower() or q in r["description"].lower() or q in r["category"].lower()]
    return resources

@app.get("/v1/wellbeing/emergency-resources")
def get_emergency_resources():
    return EMERGENCY_SUPPORT_RESOURCES

# ==================== Academic Opportunities (Section 11) ====================
@app.get("/v1/opportunities")
def list_opportunities(type: Optional[str] = None, mode: Optional[str] = None):
    items = [o for o in db.opportunities.values() if o.get("status") == "Published"]
    if type:
        items = [o for o in items if o.get("type", "").lower() == type.lower()]
    if mode:
        items = [o for o in items if o.get("mode", "").lower() == mode.lower()]
    return items

# ==================== Notifications & FCM (Section 12 & 19) ====================
@app.get("/v1/notifications")
def list_my_notifications(user: Dict[str, Any] = Depends(verify_bearer_token)):
    notifs = [n for n in db.notifications.values() if n["recipientId"] == user["uid"]]
    return sorted(notifs, key=lambda x: x.get("createdAt", ""), reverse=True)

@app.post("/v1/notifications/{notif_id}/read")
def mark_notification_read(notif_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    n = db.notifications.get(notif_id)
    if not n or n["recipientId"] != user["uid"]:
        raise HTTPException(status_code=404, detail="NOTIFICATION_NOT_FOUND")
    n["read"] = True
    db.save_to_disk()
    return n

@app.post("/v1/notifications/mark-all-read")
def mark_all_notifications_read(user: Dict[str, Any] = Depends(verify_bearer_token)):
    for n in db.notifications.values():
        if n["recipientId"] == user["uid"]:
            n["read"] = True
    db.save_to_disk()
    return {"status": "success"}

@app.post("/v1/notifications/fcm-token")
def register_fcm_token(data: FCMTokenRequest, user: Dict[str, Any] = Depends(verify_bearer_token)):
    from .services.notification_service import FCMNotificationService

    device_count = FCMNotificationService.register_device_token(
        user_id=user["uid"],
        token=data.token,
        device_info=data.deviceInfo,
    )
    return {"status": "registered", "deviceCount": device_count}


@app.delete("/v1/notifications/fcm-token")
def unregister_fcm_token(data: FCMTokenRequest, user: Dict[str, Any] = Depends(verify_bearer_token)):
    from .services.notification_service import FCMNotificationService

    removed = FCMNotificationService.remove_device_token(
        user_id=user["uid"],
        token=data.token,
    )
    return {"status": "removed" if removed else "not_found"}

# ==================== Mobile Admin & Platform Governance (Section 13) ====================
@app.post("/v1/reports")
def submit_report(data: ModerationReportCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    rid = f"rep-{uuid.uuid4().hex[:8]}"
    rec = {
        "id": rid,
        "reporterId": user["uid"],
        "status": "Under Review",
        "createdAt": utc_now_iso(),
        "updatedAt": utc_now_iso(),
        **data.dict()
    }
    db.reports[rid] = rec
    db.save_to_disk()
    return rec

@app.get("/v1/admin/reports")
def admin_list_reports(admin: Dict[str, Any] = Depends(require_admin)):
    return list(db.reports.values())

@app.get("/v1/admin/analytics")
def admin_analytics(admin: Dict[str, Any] = Depends(require_admin)):
    return {
        "totalUsers": len([u for u in db.users.values() if u.get("accountStatus") != "deleted"]),
        "totalProjects": len(db.projects),
        "totalTeamRequests": len(db.teamRequests),
        "totalLearningResources": len(db.learningResources),
        "totalOpportunities": len(db.opportunities),
        "totalConnections": len([c for c in db.connections.values() if c.get("status") == "ACTIVE"]),
        "totalFeedPosts": len(db.posts),
        "openReportsCount": len([r for r in db.reports.values() if r["status"] == "Under Review"])
    }
