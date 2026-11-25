"""
RESWAVE - Pydantic Request & Response Validation Schemas
Version 3.0 | Strict type safety for all 24+ domain entities.
"""
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, EmailStr


# ==================== Auth & Users ====================
class UserCreate(BaseModel):
    email: EmailStr
    displayName: str = Field(..., min_length=2, max_length=80)
    role: str
    country: str
    city: Optional[str] = None
    institution: Optional[str] = None
    department: Optional[str] = None
    termsAccepted: bool = True


class UserUpdate(BaseModel):
    displayName: Optional[str] = None
    headline: Optional[str] = None
    bio: Optional[str] = None
    country: Optional[str] = None
    city: Optional[str] = None
    institution: Optional[str] = None
    department: Optional[str] = None
    languages: Optional[List[str]] = None
    links: Optional[Dict[str, str]] = None
    visibility: Optional[str] = None
    discoverable: Optional[bool] = None
    preferredCollaborationMode: Optional[str] = None
    weeklyAvailabilityHours: Optional[int] = None
    timezone: Optional[str] = None
    mentorshipEnabled: Optional[bool] = None


class UserResponse(BaseModel):
    uid: str
    email: str
    displayName: str
    role: str
    country: Optional[str] = None
    city: Optional[str] = None
    institution: Optional[str] = None
    department: Optional[str] = None
    headline: Optional[str] = None
    bio: Optional[str] = None
    visibility: str = "Public to members"
    discoverable: bool = True
    accountStatus: str = "active"
    emailVerified: bool = False
    isAdmin: bool = False
    createdAt: str


# ==================== Multi-Domain Research Interests ====================
class ResearchInterestCreate(BaseModel):
    domainId: str
    subdomainId: str
    topicTags: List[str] = Field(default_factory=list)
    proficiency: str = "Beginner"  # Beginner, Intermediate, Advanced
    status: str = "Exploring"  # Exploring, Actively Researching, Published
    skills: List[str] = Field(default_factory=list)
    methods: List[str] = Field(default_factory=list)
    goals: List[str] = Field(default_factory=list)
    weeklyHoursCommitted: int = 5
    visibility: str = "Visible to members"


class ResearchInterest(ResearchInterestCreate):
    id: str
    userId: str
    createdAt: str


# ==================== Domain Recommendations ====================
class QuestionnaireInput(BaseModel):
    subjects: List[str] = Field(default_factory=list)
    problems: List[str] = Field(default_factory=list)
    workStyles: List[str] = Field(default_factory=list)
    skills: List[str] = Field(default_factory=list)
    goals: List[str] = Field(default_factory=list)
    topicInMind: Optional[str] = None


class DomainRecommendation(BaseModel):
    domainId: str
    name: str
    score: float
    fitBand: str  # Strong (>=65%), Possible (35-64%), Explore (<35%)
    reasons: List[str] = Field(default_factory=list)
    sampleTopics: List[str] = Field(default_factory=list)
    requiredSkills: List[str] = Field(default_factory=list)


# ==================== Mentorship ====================
class MentorQuestionnaireInput(BaseModel):
    currentResearch: Optional[str] = None
    researchPaperOrTopic: Optional[str] = None
    primaryDomain: Optional[str] = None
    requiredExpertise: List[str] = Field(default_factory=list)
    preferredLevel: str = "Beginner"
    preferredFormat: str = "Remote"


class MentorProfile(BaseModel):
    userId: str
    mentorshipEnabled: bool = True
    expertiseTags: List[str] = Field(default_factory=list)
    helpTypes: List[str] = Field(default_factory=list)
    menteeLevels: List[str] = Field(default_factory=list)
    formats: List[str] = Field(default_factory=lambda: ["Remote"])
    availability: str = "Available"
    maxCapacity: int = 3
    activeMenteesCount: int = 0
    preferredFrequency: str = "Bi-weekly"
    timezone: str = "UTC"
    visibility: str = "Public to members"


class MentorRequestCreate(BaseModel):
    mentorId: str
    interestId: Optional[str] = None
    helpType: str
    context: str
    format: str = "Remote"
    frequency: str = "Bi-weekly"
    timezone: str = "UTC"
    questions: List[str] = Field(default_factory=list)


class MentorDecisionRequest(BaseModel):
    status: str  # ACCEPTED, DECLINED, NEEDS_INFO
    reason: Optional[str] = None


# ==================== Team Requests & Applications ====================
class TeamRequestCreate(BaseModel):
    title: str = Field(..., min_length=5, max_length=150)
    description: str = Field(..., min_length=20)
    primaryDomain: str
    relatedDomains: List[str] = Field(default_factory=list)
    targetTopicTags: List[str] = Field(default_factory=list)
    projectStage: str = "Ideation"
    requiredRoles: List[str] = Field(default_factory=list)
    mustHaveSkills: List[str] = Field(default_factory=list)
    niceToHaveSkills: List[str] = Field(default_factory=list)
    expectedCommitmentHours: int = 8
    targetDeliverables: List[str] = Field(default_factory=list)
    targetVenueType: str = "Conference"
    targetVenueName: Optional[str] = None
    collaborationMode: str = "Remote"
    locationConstraint: Optional[str] = None
    membersNeeded: int = 2
    visibility: str = "Discoverable"


class TeamRequest(TeamRequestCreate):
    id: str
    ownerId: str
    remainingCapacity: int
    status: str = "Open"  # Open / Filled / Paused / Cancelled
    createdAt: str
    updatedAt: str


class TeamApplicationCreate(BaseModel):
    message: Optional[str] = None
    skills: List[str] = Field(default_factory=list)
    answers: List[str] = Field(default_factory=list)
    resumeUrl: Optional[str] = None
    resumeStoragePath: Optional[str] = None
    resumeFileName: Optional[str] = None


class TeamApplication(BaseModel):
    id: str
    requestId: str
    applicantId: str
    applicantName: str = "Applicant"
    applicantRole: Optional[str] = None
    applicantInstitution: Optional[str] = None
    projectTitle: Optional[str] = None
    message: Optional[str] = None
    skills: List[str] = Field(default_factory=list)
    answers: List[str] = Field(default_factory=list)
    resumeUrl: Optional[str] = None
    resumeStoragePath: Optional[str] = None
    resumeFileName: Optional[str] = None
    status: str = "Pending"  # Pending / Accepted / Declined / Clarification
    createdAt: str
    decidedAt: Optional[str] = None


# ==================== Projects & Workspaces ====================
class ProjectTaskCreate(BaseModel):
    title: str
    assigneeId: Optional[str] = None
    dueDate: Optional[str] = None
    status: str = "Todo"  # Todo, In Progress, Review, Done
    priority: str = "Medium"


class ProjectTask(ProjectTaskCreate):
    id: str
    projectId: str
    createdAt: str


class ProjectMilestoneCreate(BaseModel):
    title: str
    targetDate: str
    description: Optional[str] = None
    completed: bool = False


class ProjectMilestone(ProjectMilestoneCreate):
    id: str
    projectId: str
    createdAt: str


# ==================== Groups ====================
class GroupCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=100)
    description: str = Field(..., min_length=5)
    primaryDomain: str = "general"
    topics: List[str] = Field(default_factory=list)
    purpose: str = ""
    rules: str = ""
    membershipMode: str = "Open"  # Open, Request to join, Invite only
    visibility: str = "Discoverable"


class Group(GroupCreate):
    id: str
    ownerId: str
    memberCount: int = 1
    createdAt: str


# ==================== Feed & Peer Support ====================
class FeedPostCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=3000)
    audience: str = "Members"
    domainId: Optional[str] = None
    groupId: Optional[str] = None
    topicTags: List[str] = Field(default_factory=list)


class FeedPost(FeedPostCreate):
    id: str
    authorId: str
    authorName: str
    authorRole: Optional[str] = None
    authorInstitution: Optional[str] = None
    likeCount: int = 0
    commentCount: int = 0
    userLiked: bool = False
    createdAt: str


class CommentCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=1000)


class CommentResponse(BaseModel):
    id: str
    postId: str
    authorId: str
    authorName: str
    content: str
    createdAt: str


# ==================== Well-being & Professional Support ====================
class MoodCheckinCreate(BaseModel):
    mood: str
    intensity: int = Field(..., ge=1, le=5)
    factors: List[str] = Field(default_factory=list)
    privateNotes: Optional[str] = None


class MoodEntry(MoodCheckinCreate):
    id: str
    userId: str
    createdAt: str


class PeerSupportPostCreate(BaseModel):
    category: str
    text: str = Field(..., min_length=5, max_length=2000)
    hideIdentity: bool = True
    safetyAcknowledged: bool = True


class PeerSupportPost(BaseModel):
    id: str
    authorId: str
    authorName: str
    category: str
    text: str
    hideIdentity: bool
    likesCount: int = 0
    repliesCount: int = 0
    userLiked: bool = False
    createdAt: str


class ProfessionalSupportResource(BaseModel):
    id: str
    name: str
    category: str  # Counsellor / Mental Health Professional / Academic Wellbeing Coach
    institutionOrOrganization: str
    qualifications: str
    description: str
    verifiedBy: str
    lastVerifiedDate: str
    contactUrlOrEmail: str
    availabilityNote: str


# ==================== Paper Library ====================
class PaperLibraryItem(BaseModel):
    id: str
    userId: str
    title: str
    authors: List[str] = Field(default_factory=list)
    doi: Optional[str] = None
    year: Optional[int] = None
    url: Optional[str] = None
    storageReference: Optional[str] = None
    storagePath: Optional[str] = None
    fileSize: Optional[int] = None
    readingStatus: str = "To Read"  # To Read, Reading, Completed
    privateNotes: Optional[str] = None
    domainId: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    createdAt: str
    updatedAt: Optional[str] = None


class Publication(BaseModel):
    id: str
    userId: str
    title: str
    authors: List[str]
    venue: str
    year: int
    doi: Optional[str] = None
    url: Optional[str] = None


# ==================== Learning Hub & Opportunities ====================
class LearningResource(BaseModel):
    id: str
    title: str
    description: str
    domain: str
    subdomain: Optional[str] = None
    topicTags: List[str] = Field(default_factory=list)
    level: str  # Beginner, Intermediate, Advanced
    format: str
    estimatedMinutes: int
    sourceName: str
    officialSourceUrl: str
    verifiedBy: str
    lastVerifiedDate: str
    status: str = "Published"


class Opportunity(BaseModel):
    id: str
    title: str
    type: str  # Conference, Grant, Fellowship, Call for Papers
    organizer: str
    officialSourceUrl: str
    primaryDomain: str
    deadline: str
    startDate: Optional[str] = None
    location: Optional[str] = None
    description: str
    verifiedBy: str
    lastVerifiedDate: str
    status: str = "Active"


# ==================== Network, Messages & Notifications ====================
class ConnectionRequestCreate(BaseModel):
    note: Optional[str] = None


class ConnectionRequestResponse(BaseModel):
    id: str
    senderId: str
    receiverId: str
    note: Optional[str] = None
    status: str  # PENDING, ACCEPTED, DECLINED, WITHDRAWN
    createdAt: str


class NetworkSummaryResponse(BaseModel):
    connectionsCount: int
    followersCount: int
    followingCount: int
    pendingIncomingRequestsCount: int
    pendingOutgoingRequestsCount: int


class SendMessageRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000)


class MessageResponse(BaseModel):
    id: str
    conversationId: str
    senderId: str
    content: str
    createdAt: str


class ConversationResponse(BaseModel):
    id: str
    participantIds: List[str]
    lastMessage: Optional[str] = None
    lastMessageTime: Optional[str] = None


class FCMTokenRequest(BaseModel):
    token: str
    deviceInfo: Optional[str] = None


class ModerationReportCreate(BaseModel):
    targetType: str  # post, comment, user, group
    targetId: str
    reason: str
    details: Optional[str] = None


class ModerationReport(ModerationReportCreate):
    id: str
    reporterId: str
    status: str = "Pending"  # Pending, Reviewed, Dismissed, Actioned
    createdAt: str
