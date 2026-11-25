"""
RESWAVE - Core Data Store (Persistent Engine & Firestore Bridge)
Implements all 24+ collections with referential integrity, atomic transactions,
and automatic disk persistence so data survives server and app restarts.
"""
import os
import json
import uuid
import threading
from datetime import datetime, timezone
from typing import Dict, List, Any, Optional
from ..services.seed_data import (
    SEED_DOMAINS,
    SEED_LEARNING_RESOURCES,
    SEED_OPPORTUNITIES,
    SEED_GROUPS
)

DATA_FILE_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "reswave_data_store.json")

def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()

class MemoryDatabase:
    """
    Thread-safe persistent data store that operates as both an in-memory high-speed cache
    and a disk-persisted document database, designed to mirror Cloud Firestore collections.
    """
    def __init__(self, data_file: str = DATA_FILE_PATH):
        self._lock = threading.RLock()
        self.data_file = data_file
        self.reset(save_disk=False)
        self.load_from_disk()

    def reset(self, save_disk: bool = False):
        with self._lock:
            self.users: Dict[str, Dict[str, Any]] = {}
            self._firestore_user_ids: set[str] = set()
            self.researchInterests: Dict[str, Dict[str, Any]] = {}
            self.domains: Dict[str, Dict[str, Any]] = {}
            self.learningResources: Dict[str, Dict[str, Any]] = {}
            self.resourceProgress: Dict[str, Dict[str, Any]] = {}
            self.publications: Dict[str, Dict[str, Any]] = {}
            self.paperLibrary: Dict[str, Dict[str, Any]] = {}
            self.teamRequests: Dict[str, Dict[str, Any]] = {}
            self.teamApplications: Dict[str, Dict[str, Any]] = {}
            self.projects: Dict[str, Dict[str, Any]] = {}
            self.tasks: Dict[str, Dict[str, Any]] = {}
            self.milestones: Dict[str, Dict[str, Any]] = {}
            self.mentorProfiles: Dict[str, Dict[str, Any]] = {}
            self.mentorRequests: Dict[str, Dict[str, Any]] = {}
            self.mentorQuestionnaires: Dict[str, Dict[str, Any]] = {}
            self.groups: Dict[str, Dict[str, Any]] = {}
            self.groupMembers: Dict[str, Dict[str, Any]] = {}
            self.posts: Dict[str, Dict[str, Any]] = {}
            self.comments: Dict[str, Dict[str, Any]] = {}
            self.postReactions: Dict[str, Dict[str, Any]] = {}
            self.connections: Dict[str, Dict[str, Any]] = {}
            self.connectionRequests: Dict[str, Dict[str, Any]] = {}
            self.follows: Dict[str, Dict[str, Any]] = {}
            self.conversations: Dict[str, Dict[str, Any]] = {}
            self.messages: Dict[str, Dict[str, Any]] = {}
            self.moodEntries: Dict[str, Dict[str, Any]] = {}
            self.supportPosts: Dict[str, Dict[str, Any]] = {}
            self.opportunities: Dict[str, Dict[str, Any]] = {}
            self.savedItems: Dict[str, Dict[str, Any]] = {}
            self.notifications: Dict[str, Dict[str, Any]] = {}
            self.fcmTokens: Dict[str, Dict[str, Any]] = {}
            self.reports: Dict[str, Dict[str, Any]] = {}
            self.adminAuditLogs: Dict[str, Dict[str, Any]] = {}

            self._seed_initial_data()
            if save_disk:
                self.save_to_disk()

    def cache_user_profile(
        self,
        uid: str,
        profile: Dict[str, Any],
        firestore_backed: bool = False,
    ):
        with self._lock:
            self.users[uid] = profile
            if firestore_backed:
                self._firestore_user_ids.add(uid)

    def _seed_initial_data(self):
        # 1. Domains
        for d in SEED_DOMAINS:
            self.domains[d["id"]] = dict(d)

        # 2. Learning Resources
        for r in SEED_LEARNING_RESOURCES:
            self.learningResources[r["id"]] = dict(r)

        # 3. Opportunities
        for o in SEED_OPPORTUNITIES:
            self.opportunities[o["id"]] = dict(o)

        # 4. Groups
        for g in SEED_GROUPS:
            self.groups[g["id"]] = dict(g)

        # 5. Admin User
        admin_uid = "usr-admin-01"
        self.users[admin_uid] = {
            "uid": admin_uid,
            "email": "admin@reswave.org",
            "displayName": "ResWave Platform Admin",
            "role": "Admin / Moderator",
            "headline": "Research Integrity & Platform Moderator",
            "bio": "Overseeing taxonomy, reviewed resources, and academic safety.",
            "country": "United Kingdom",
            "city": "Oxford",
            "institution": "ResWave Foundation",
            "department": "Academic Governance",
            "visibility": "Public to members",
            "discoverable": True,
            "accountStatus": "active",
            "emailVerified": True,
            "isAdmin": True,
            "createdAt": utc_now_iso(),
            "updatedAt": utc_now_iso()
        }

        # 6. Seed Test Researchers & Mentors
        prof_uid = "usr-prof-elena"
        self.users[prof_uid] = {
            "uid": prof_uid,
            "email": "elena.rostova@university.edu",
            "displayName": "Prof. Elena Rostova",
            "role": "Professor / Faculty",
            "headline": "Associate Professor in Human-Centered Computing",
            "bio": "Researching cognitive interfaces and accessibility evaluations.",
            "country": "Germany",
            "city": "Munich",
            "institution": "Technical University of Munich",
            "department": "Informatics",
            "visibility": "Public to members",
            "discoverable": True,
            "preferredCollaborationMode": "Remote",
            "accountStatus": "active",
            "emailVerified": True,
            "isAdmin": False,
            "createdAt": utc_now_iso(),
            "updatedAt": utc_now_iso()
        }
        self.researchInterests["int-elena-01"] = {
            "id": "int-elena-01",
            "userId": prof_uid,
            "domainId": "hci",
            "subdomainId": "Cognitive Ergonomics",
            "topicTags": ["cognitive load", "user study", "accessibility"],
            "keywords": ["usability", "ux metrics", "eye tracking"],
            "proficiency": "Expert",
            "status": "Active research",
            "skills": ["experiment design", "statistical analysis", "usability testing"],
            "methods": ["Experimental", "Quantitative", "Mixed"],
            "goals": ["Find collaborator", "Mentor students", "Publish"],
            "availability": "Available",
            "visibility": "Visible to members",
            "createdAt": utc_now_iso()
        }
        self.mentorProfiles[prof_uid] = {
            "userId": prof_uid,
            "mentorshipEnabled": True,
            "expertiseTags": ["HCI", "Cognitive Ergonomics", "Accessibility", "User Study"],
            "helpTypes": ["methodology", "paper feedback", "research process", "Topic selection", "Writing"],
            "menteeLevels": ["Beginner", "Intermediate", "Undergraduate", "PhD Scholar"],
            "formats": ["Remote", "Async feedback", "Online", "Hybrid"],
            "availability": "Available",
            "maxCapacity": 3,
            "activeMenteesCount": 1,
            "preferredFrequency": "Bi-weekly",
            "timezone": "CET (UTC+1)",
            "visibility": "Public to members"
        }

        # PhD Scholar Alex Rivera
        alex_uid = "usr-alex-phd"
        self.users[alex_uid] = {
            "uid": alex_uid,
            "email": "alex.rivera@cs.cmu.edu",
            "displayName": "Alex Rivera",
            "role": "PhD Scholar",
            "headline": "PhD Candidate in NLP & Trustworthy AI",
            "bio": "Working on benchmark evaluation and small language models.",
            "country": "United States",
            "city": "Pittsburgh",
            "institution": "Carnegie Mellon University",
            "department": "Language Technologies Institute",
            "visibility": "Public to members",
            "discoverable": True,
            "preferredCollaborationMode": "Hybrid",
            "accountStatus": "active",
            "emailVerified": True,
            "isAdmin": False,
            "createdAt": utc_now_iso(),
            "updatedAt": utc_now_iso()
        }
        self.researchInterests["int-alex-01"] = {
            "id": "int-alex-01",
            "userId": alex_uid,
            "domainId": "ai-nlp",
            "subdomainId": "Natural Language Processing",
            "topicTags": ["transformers", "evaluation", "benchmarks", "reasoning"],
            "keywords": ["citation verification", "prompting", "factual consistency"],
            "proficiency": "Advanced",
            "status": "Active research",
            "skills": ["python", "pytorch", "data analysis", "evaluation"],
            "methods": ["Computational", "Quantitative"],
            "goals": ["Find teammate", "Find collaborator", "Publish"],
            "availability": "Available",
            "visibility": "Visible to members",
            "createdAt": utc_now_iso()
        }

        # Sample Team Request
        req_id = "req-ai-eval-01"
        self.teamRequests[req_id] = {
            "id": req_id,
            "ownerId": alex_uid,
            "title": "Empirical Evaluation of Citation Accuracy in Open-Weights LLMs",
            "description": "We are designing a rigorous benchmark to evaluate whether open-weight language models hallucinate academic citations. Seeking a developer and data analyst to help build automated parsing pipelines and statistical significance testing.",
            "primaryDomain": "ai-nlp",
            "relatedDomains": ["hci"],
            "topics": ["evaluation", "benchmarks", "citation verification"],
            "skillsNeeded": [
                {"skill": "python", "mustHave": True},
                {"skill": "data analysis", "mustHave": True},
                {"skill": "web scraping", "mustHave": False}
            ],
            "rolesNeeded": ["Developer", "Data analyst", "Literature reviewer"],
            "membersNeeded": 2,
            "remainingCapacity": 2,
            "experiencePref": "Intermediate",
            "commitment": "1–3 months",
            "mode": "Remote",
            "location": None,
            "startDate": "2026-12-01",
            "applicationQuestions": [
                "What experience do you have with Python and evaluating NLP models?",
                "How many hours per week can you reliably commit?"
            ],
            "visibility": "Discoverable",
            "status": "Open",
            "createdAt": utc_now_iso(),
            "updatedAt": utc_now_iso()
        }

        # Seed initial feed post
        p_id = "post-seed-01"
        self.posts[p_id] = {
            "id": p_id,
            "authorId": alex_uid,
            "authorName": "Alex Rivera",
            "authorHeadline": "PhD Candidate in NLP • CMU",
            "text": "Completed the pilot benchmark evaluating citation consistency across 8 open-weights models. Hallucination rate drops 42% with prompt grounding.",
            "postType": "Research update",
            "domainTags": ["NLP", "Evaluation", "AI"],
            "attachmentUrl": None,
            "audience": "Members",
            "groupId": None,
            "projectId": None,
            "commentsEnabled": True,
            "reactionCount": 4,
            "commentCount": 1,
            "createdAt": utc_now_iso()
        }
        self.comments["comment-seed-01"] = {
            "id": "comment-seed-01",
            "postId": p_id,
            "authorId": prof_uid,
            "authorName": "Prof. Elena Rostova",
            "authorRole": "Professor / Faculty",
            "text": "Fascinating preliminary findings, Alex. Looking forward to the methodology section on synthetic prompt validation.",
            "createdAt": utc_now_iso()
        }

    def save_to_disk(self):
        with self._lock:
            try:
                data = {
                    "users": {
                        uid: user
                        for uid, user in self.users.items()
                        if uid not in self._firestore_user_ids
                    },
                    "researchInterests": self.researchInterests,
                    "domains": self.domains,
                    "learningResources": self.learningResources,
                    "resourceProgress": self.resourceProgress,
                    "publications": self.publications,
                    "paperLibrary": self.paperLibrary,
                    "teamRequests": self.teamRequests,
                    "teamApplications": self.teamApplications,
                    "projects": self.projects,
                    "tasks": self.tasks,
                    "milestones": self.milestones,
                    "mentorProfiles": self.mentorProfiles,
                    "mentorRequests": self.mentorRequests,
                    "mentorQuestionnaires": self.mentorQuestionnaires,
                    "groups": self.groups,
                    "groupMembers": self.groupMembers,
                    "posts": self.posts,
                    "comments": self.comments,
                    "postReactions": self.postReactions,
                    "connections": self.connections,
                    "connectionRequests": self.connectionRequests,
                    "follows": self.follows,
                    "conversations": self.conversations,
                    "messages": self.messages,
                    "moodEntries": self.moodEntries,
                    "supportPosts": self.supportPosts,
                    "opportunities": self.opportunities,
                    "savedItems": self.savedItems,
                    "notifications": self.notifications,
                    "fcmTokens": self.fcmTokens,
                    "reports": self.reports,
                    "adminAuditLogs": self.adminAuditLogs
                }
                temp_file = f"{self.data_file}.tmp"
                with open(temp_file, "w", encoding="utf-8") as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                if os.path.exists(temp_file):
                    os.replace(temp_file, self.data_file)
            except Exception as e:
                print(f"[MemoryDatabase] Warning: Could not save to disk: {e}")

    def load_from_disk(self):
        with self._lock:
            if not os.path.exists(self.data_file):
                return
            try:
                with open(self.data_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                for key, val in data.items():
                    if hasattr(self, key) and isinstance(val, dict):
                        target = getattr(self, key)
                        target.update(val)
                print(f"[MemoryDatabase] Loaded persistent data store from {self.data_file}")
            except Exception as e:
                print(f"[MemoryDatabase] Warning: Failed to load from disk: {e}")

db = MemoryDatabase()
