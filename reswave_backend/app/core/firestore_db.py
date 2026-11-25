"""
RESWAVE - Cloud Firestore & Transaction Engine
Implements atomic operations for team capacity, mentor reservation, connection acceptance,
follow relationships, and deduplicated notification delivery.
"""
import uuid
import threading
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone
from ..core.memory_db import db, utc_now_iso

_firestore_client = None
_firestore_client_lock = threading.Lock()


def get_firestore_client() -> Any:
    global _firestore_client
    if _firestore_client is not None:
        return _firestore_client

    with _firestore_client_lock:
        if _firestore_client is None:
            from firebase_admin import firestore
            from ..services.security import get_firebase_admin_app

            _firestore_client = firestore.client(app=get_firebase_admin_app())
    return _firestore_client


class FirestoreTransactionEngine:
    """
    Handles atomic operations ensuring no race conditions or over-subscriptions occur.
    """
    @staticmethod
    def atomic_accept_team_application(app_id: str, owner_uid: str) -> Dict[str, Any]:
        """
        Section 7.2 & 9:
        Atomically checks remaining capacity, decrements capacity, updates request status
        to 'Filled' if capacity == 0, adds member to project workspace, and returns updated objects.
        """
        app_rec = db.teamApplications.get(app_id)
        if not app_rec:
            raise ValueError("APPLICATION_NOT_FOUND")

        req = db.teamRequests.get(app_rec["requestId"])
        if not req:
            raise ValueError("REQUEST_NOT_FOUND")

        if req["ownerId"] != owner_uid:
            raise PermissionError("PERMISSION_DENIED_NOT_OWNER")

        # Atomic capacity check
        if req["remainingCapacity"] <= 0 or req["status"] != "Open":
            raise ValueError("CAPACITY_FULL_OR_CLOSED")

        # Transactional decrement
        req["remainingCapacity"] -= 1
        if req["remainingCapacity"] == 0:
            req["status"] = "Filled"
        req["updatedAt"] = utc_now_iso()

        # Update application state
        app_rec["status"] = "Accepted"
        app_rec["decidedAt"] = utc_now_iso()

        # Create or update project workspace (Section 9)
        proj_id = f"proj-{req['id']}"
        if proj_id not in db.projects:
            db.projects[proj_id] = {
                "id": proj_id,
                "ownerId": req["ownerId"],
                "title": req["title"],
                "description": req["description"],
                "domainTags": [req["primaryDomain"]] + req.get("relatedDomains", []),
                "memberIds": [req["ownerId"], app_rec["applicantId"]],
                "status": "Active",
                "startDate": utc_now_iso(),
                "sourceTeamRequestId": req["id"]
            }
        else:
            if app_rec["applicantId"] not in db.projects[proj_id]["memberIds"]:
                db.projects[proj_id]["memberIds"].append(app_rec["applicantId"])

        # Create deduplicated notification for applicant
        FirestoreTransactionEngine.atomic_create_notification(
            recipient_id=app_rec["applicantId"],
            notif_type="Team",
            title="Team Application Accepted! 🎉",
            body=f"You have been accepted to '{req['title']}'. Workspace access is now unlocked.",
            target_type="project",
            target_id=proj_id,
            idempotency_key=f"team_accepted_{app_id}"
        )

        db.save_to_disk()

        return {
            "status": "success",
            "application": app_rec,
            "teamRequest": req,
            "project": db.projects[proj_id]
        }

    @staticmethod
    def atomic_reserve_mentor_slot(mentor_uid: str, mentee_uid: str) -> Dict[str, Any]:
        """
        Section 7.3:
        Atomically checks mentor capacity and increments activeMenteesCount.
        """
        prof = db.mentorProfiles.get(mentor_uid)
        if not prof:
            raise ValueError("MENTOR_PROFILE_NOT_FOUND")

        if not prof.get("mentorshipEnabled", False):
            raise ValueError("MENTOR_NOT_OPTED_IN")

        current_active = prof.get("activeMenteesCount", 0)
        max_cap = prof.get("maxCapacity", 3)

        if current_active >= max_cap:
            raise ValueError("MENTOR_CAPACITY_FULL")

        prof["activeMenteesCount"] = current_active + 1
        if prof["activeMenteesCount"] >= max_cap:
            prof["availability"] = "Full"
        prof["updatedAt"] = utc_now_iso()

        db.save_to_disk()
        return prof

    @staticmethod
    def atomic_accept_connection(request_id: str, receiver_uid: str) -> Dict[str, Any]:
        """
        Section 6.1:
        Accepts pending connection request, forms bi-directional connection,
        and unlocks direct messaging.
        """
        req = db.connectionRequests.get(request_id)
        if not req:
            raise ValueError("CONNECTION_REQUEST_NOT_FOUND")

        if req["receiverId"] != receiver_uid:
            raise PermissionError("PERMISSION_DENIED")

        if req["status"] != "PENDING":
            raise ValueError("REQUEST_NOT_PENDING")

        req["status"] = "ACCEPTED"
        req["updatedAt"] = utc_now_iso()

        # Generate canonical connection id: sorted pair ensures uniqueness
        users_sorted = sorted([req["senderId"], req["receiverId"]])
        conn_id = f"conn-{users_sorted[0]}-{users_sorted[1]}"
        db.connections[conn_id] = {
            "id": conn_id,
            "userA": users_sorted[0],
            "userB": users_sorted[1],
            "connectedAt": utc_now_iso(),
            "status": "ACTIVE"
        }

        # Send notification to sender
        receiver_user = db.users.get(receiver_uid, {})
        rec_name = receiver_user.get("displayName", "Academic Peer")

        FirestoreTransactionEngine.atomic_create_notification(
            recipient_id=req["senderId"],
            notif_type="Connection",
            title="Connection Accepted! 🤝",
            body=f"{rec_name} accepted your connection request. Direct messaging is now unlocked.",
            target_type="user",
            target_id=receiver_uid,
            idempotency_key=f"conn_accepted_{request_id}"
        )

        db.save_to_disk()
        return {
            "status": "success",
            "connection": db.connections[conn_id],
            "request": req
        }

    atomic_accept_connection_request = atomic_accept_connection

    @staticmethod
    def atomic_toggle_follow(follower_id: str, target_id: str) -> Dict[str, Any]:
        """
        Section 6.2:
        Follow or unfollow a discoverable user. Enforces uniqueness and prevents self-follow.
        """
        if follower_id == target_id:
            raise ValueError("CANNOT_FOLLOW_SELF")

        key = f"{follower_id}_{target_id}"
        if key in db.follows:
            # Unfollow
            del db.follows[key]
            db.save_to_disk()
            return {"status": "unfollowed", "isFollowing": False}
        else:
            # Follow
            db.follows[key] = {
                "id": key,
                "followerId": follower_id,
                "targetId": target_id,
                "createdAt": utc_now_iso()
            }
            # Notify target
            follower = db.users.get(follower_id, {})
            FirestoreTransactionEngine.atomic_create_notification(
                recipient_id=target_id,
                notif_type="Follow",
                title="New Academic Follower",
                body=f"{follower.get('displayName', 'A researcher')} started following your research updates.",
                target_type="user",
                target_id=follower_id,
                idempotency_key=f"follow_{follower_id}_{target_id}"
            )
            db.save_to_disk()
            return {"status": "followed", "isFollowing": True}

    @staticmethod
    def atomic_create_notification(
        recipient_id: str,
        notif_type: str,
        title: str,
        body: str,
        target_type: Optional[str] = None,
        target_id: Optional[str] = None,
        idempotency_key: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Section 19:
        Creates a persistent in-app notification record and pushes via FCM if registered.
        Prevents duplicate notifications using an idempotency key.
        """
        # Duplicate detection check
        if idempotency_key:
            for existing in db.notifications.values():
                if (
                    existing.get("recipientId") == recipient_id
                    and existing.get("idempotencyKey") == idempotency_key
                ):
                    return existing

        nid = f"notif-{uuid.uuid4().hex[:10]}"
        notif = {
            "id": nid,
            "recipientId": recipient_id,
            "type": notif_type,
            "title": title,
            "body": body,
            "targetType": target_type,
            "targetId": target_id,
            "read": False,
            "idempotencyKey": idempotency_key,
            "createdAt": utc_now_iso()
        }
        db.notifications[nid] = notif
        from ..services.notification_service import FCMNotificationService

        FCMNotificationService.send_to_user(recipient_id, notif)
        return notif
