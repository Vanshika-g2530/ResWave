"""
RESWAVE - Seed Taxonomy, Learning Resources, Opportunities & Peer Support
Section 0 & 1.3: Seed only admin-owned taxonomy, reviewed learning content, and manual listings.
"""
from typing import List, Dict, Any

SEED_DOMAINS: List[Dict[str, Any]] = [
    {
        "id": "hci",
        "name": "Human-Computer Interaction (HCI)",
        "parentId": None,
        "shortDescription": "Designing, building, and evaluating technologies that empower humans.",
        "beginnerExplanation": "HCI investigates the intersection of computer science, behavioural psychology, and design to create intuitive, accessible interfaces.",
        "subdomains": ["Cognitive Ergonomics", "Accessibility", "Explainable AI (XAI)", "Ubiquitous Computing"],
        "keywords": ["usability", "ux", "cognitive load", "accessibility", "user study", "prototyping", "interfaces"],
        "subjectTags": ["computing", "design", "psychology"],
        "problemTags": ["human behaviour", "technology", "design/experience"],
        "workStyleTags": ["building prototypes", "designing experiences", "interviews/surveys"],
        "skillTags": ["design", "observation/interviews", "programming", "data analysis"],
        "goalTags": ["explore", "solve practical problem", "build portfolio", "publish"],
        "sampleResearchQuestions": [
            "How does visual cognitive load affect decision confidence in high-stakes dashboards?",
            "What interface adaptations reduce latency frustration for neurodivergent learners?"
        ],
        "commonMethods": ["Qualitative", "Design-based", "Mixed", "Experimental"],
        "learningResourceIds": ["res-hci-01", "res-lit-01"],
        "status": "Published",
        "reviewedAt": "2026-11-15T10:00:00Z",
        "version": 1
    },
    {
        "id": "ai-nlp",
        "name": "Artificial Intelligence & NLP",
        "parentId": None,
        "shortDescription": "Natural language understanding, machine learning foundations, and ethical AI systems.",
        "beginnerExplanation": "Explores how computational models understand, generate, and reason with structured data and human language.",
        "subdomains": ["Natural Language Processing", "Machine Learning", "Ethical AI", "Information Retrieval"],
        "keywords": ["nlp", "machine learning", "transformers", "evaluation", "benchmarks", "reasoning", "bias"],
        "subjectTags": ["computing", "mathematics"],
        "problemTags": ["technology", "data/patterns", "devices/engineering"],
        "workStyleTags": ["analysing data", "building prototypes", "experiments"],
        "skillTags": ["programming", "statistics", "data analysis"],
        "goalTags": ["publish", "prepare higher studies", "contribute to a field"],
        "sampleResearchQuestions": [
            "How can domain-adapted small language models perform factual citation verification?",
            "What algorithmic debiasing methods maintain accuracy in low-resource multilingual corpora?"
        ],
        "commonMethods": ["Computational", "Quantitative", "Experimental"],
        "learningResourceIds": ["res-ethics-01", "res-method-01"],
        "status": "Published",
        "reviewedAt": "2026-11-16T14:30:00Z",
        "version": 1
    },
    {
        "id": "cog-psych",
        "name": "Cognitive Psychology & Neuroscience",
        "parentId": None,
        "shortDescription": "Understanding mental processes: perception, memory, attention, and decision-making.",
        "beginnerExplanation": "Examines how the human brain processes information, stores knowledge, and guides behavior.",
        "subdomains": ["Working Memory", "Attention", "Behavioural Decision Theory", "Neurocognition"],
        "keywords": ["memory", "attention", "perception", "reaction time", "cognition", "decision making"],
        "subjectTags": ["psychology", "biology", "social sciences"],
        "problemTags": ["human behaviour", "health", "society"],
        "workStyleTags": ["experiments", "analysing data", "interviews/surveys"],
        "skillTags": ["statistics", "data analysis", "observation/interviews", "writing"],
        "goalTags": ["prepare higher studies", "publish", "explore"],
        "sampleResearchQuestions": [
            "How does digital notification frequency disrupt working memory consolidation during deep work?",
            "What environmental factors modulate cognitive resilience under acute academic stress?"
        ],
        "commonMethods": ["Experimental", "Quantitative", "Mixed"],
        "learningResourceIds": ["res-method-01", "res-lit-01"],
        "status": "Published",
        "reviewedAt": "2026-11-14T09:00:00Z",
        "version": 1
    },
    {
        "id": "env-science",
        "name": "Environmental Science & Climate",
        "parentId": None,
        "shortDescription": "Atmospheric systems, environmental monitoring, sustainability modeling, and biodiversity.",
        "beginnerExplanation": "Investigates earth systems, climate changes, and environmental preservation strategies using empirical science.",
        "subdomains": ["Climate Modeling", "Ecological Impact", "Renewable Resources", "Environmental Policy"],
        "keywords": ["sustainability", "climate", "carbon", "sensors", "field data", "ecology"],
        "subjectTags": ["environment", "biology", "physics"],
        "problemTags": ["climate", "health", "society", "devices/engineering"],
        "workStyleTags": ["fieldwork", "analysing data", "experiments"],
        "skillTags": ["data analysis", "lab work", "writing", "statistics"],
        "goalTags": ["solve practical problem", "contribute to a field", "explore"],
        "sampleResearchQuestions": [
            "What predictive microclimate models best forecast urban heat island vulnerabilities?",
            "How do agricultural drainage patterns impact downstream microbial biodiversity?"
        ],
        "commonMethods": ["Quantitative", "Computational", "Experimental"],
        "learningResourceIds": ["res-lit-01", "res-method-01"],
        "status": "Published",
        "reviewedAt": "2026-11-12T11:00:00Z",
        "version": 1
    }
]

SEED_LEARNING_RESOURCES: List[Dict[str, Any]] = [
    {
        "id": "res-ethics-01",
        "title": "Research Integrity & Academic Ethics Fundamentals",
        "category": "Research basics and research ethics",
        "domainTags": ["General Research", "Ethics", "All Disciplines"],
        "level": "Beginner",
        "format": "Article",
        "summary": "Core principles of research integrity: authorship ethics, participant consent, and data transparency.",
        "contentOrUrl": "Research ethics establish the foundational pact between science and society. Key pillars include: 1) Informed consent without coercion, 2) Data fabrication and falsification zero-tolerance, 3) Fair authorship attributing significant intellectual contributions, and 4) Full conflict of interest disclosure.",
        "sourceName": "ResWave Academic Editorial Board",
        "sourceUrl": "https://reswave.org/guidance/ethics-foundations",
        "durationMinutes": 15,
        "prerequisites": ["None"],
        "authorOrEditor": "Dr. Eleanor Vance, ResWave Ethics Chair",
        "reviewedDate": "2026-11-10",
        "nextReviewDate": "2027-05-10",
        "status": "Published"
    },
    {
        "id": "res-lit-01",
        "title": "Systematic Literature Reviews & Spotting the Research Gap",
        "category": "Literature review and identifying a research gap",
        "domainTags": ["Literature Review", "HCI", "Cognitive Science"],
        "level": "Intermediate",
        "format": "Checklist",
        "summary": "A methodical 5-step checklist for synthesising literature and isolating an authentic, defensible research gap.",
        "contentOrUrl": "Checklist: 1. Formulate specific search strings across indexed repositories. 2. Establish strict inclusion and exclusion criteria. 3. Construct a synthesis matrix extracting methodology, sample size, and limitations. 4. Identify contradictions or unexamined contexts (the Gap). 5. Formulate your research question directly addressing that void.",
        "sourceName": "ResWave Methodology Collective",
        "sourceUrl": "https://reswave.org/guidance/lit-review-checklist",
        "durationMinutes": 25,
        "prerequisites": ["Basic topic domain knowledge"],
        "authorOrEditor": "Prof. Marcus Thorne",
        "reviewedDate": "2026-11-12",
        "nextReviewDate": "2027-05-12",
        "status": "Published"
    },
    {
        "id": "res-method-01",
        "title": "Formulating Testable Hypotheses & Methodology Selection",
        "category": "Research questions, hypotheses and methodology",
        "domainTags": ["Methodology", "Quantitative", "Qualitative"],
        "level": "Beginner",
        "format": "Article",
        "summary": "Distinguishing exploratory questions from falsifiable hypotheses and matching them to appropriate empirical methods.",
        "contentOrUrl": "A robust research hypothesis must be directional, measurable, and falsifiable. When choosing methods: Qualitative approaches uncover 'why' and 'how' through thematic analysis; Quantitative methods test relationships and variance; Mixed methods triangulate both for comprehensive validity.",
        "sourceName": "Open Research Methods Consortium",
        "sourceUrl": "https://openresearch.org/methods/hypothesis-design",
        "durationMinutes": 20,
        "prerequisites": ["res-ethics-01"],
        "authorOrEditor": "Dr. Priya Nair",
        "reviewedDate": "2026-11-15",
        "nextReviewDate": "2027-05-15",
        "status": "Published"
    },
    {
        "id": "res-pub-01",
        "title": "Navigating Peer Review, Revisions & Rebuttals",
        "category": "Publication process, peer review, revisions and responding to reviewers",
        "domainTags": ["Publishing", "Writing", "Peer Review"],
        "level": "Advanced",
        "format": "Article",
        "summary": "How to structure courteous, evidence-backed rebuttal letters and manage major revision requests constructively.",
        "contentOrUrl": "Reviewers are your paper's first rigorous readers. Golden rules for rebuttals: 1) Thank reviewers for constructive critiques, 2) Quote the exact comment followed by your direct answer and line references, 3) Never argue defensively—demonstrate empirical improvements with added experiments or clarifications.",
        "sourceName": "Academic Publishing Advisory",
        "sourceUrl": "https://apa-advice.org/peer-review-rebuttals",
        "durationMinutes": 30,
        "prerequisites": ["Draft manuscript completed"],
        "authorOrEditor": "Prof. David Chen",
        "reviewedDate": "2026-11-17",
        "nextReviewDate": "2027-05-17",
        "status": "Published"
    }
]

SEED_OPPORTUNITIES: List[Dict[str, Any]] = [
    {
        "id": "opp-chi-2027",
        "type": "Conference",
        "title": "ACM CHI Conference on Human Factors in Computing Systems",
        "organiser": "ACM SIGCHI",
        "description": "The premier international conference of Human-Computer Interaction, featuring papers on interaction techniques, cognitive engineering, and accessibility.",
        "tags": ["HCI", "User Experience", "Accessibility", "Design"],
        "startDate": "2027-04-24",
        "endDate": "2027-04-29",
        "submissionDeadline": "2026-12-15",
        "mode": "Hybrid",
        "location": "Honolulu, Hawaii, USA",
        "eligibility": "Open to all researchers and students globally (check official guidelines).",
        "officialSourceUrl": "https://chi2027.acm.org",
        "registrationUrl": "https://chi2027.acm.org/registration",
        "lastVerifiedDate": "2026-11-18",
        "status": "Published",
        "reviewedBy": "ResWave Academic Curator"
    },
    {
        "id": "opp-grant-nsf-01",
        "type": "Grant",
        "title": "Graduate Research Fellowship in Human-Centered AI",
        "organiser": "National Science Foundation",
        "description": "Fellowship supporting early-career graduate students in STEM disciplines conducting research on trustworthy and interactive computing.",
        "tags": ["AI & NLP", "HCI", "Funding", "Fellowship"],
        "startDate": "2027-01-10",
        "endDate": "2027-01-15",
        "submissionDeadline": "2026-12-01",
        "mode": "Online",
        "location": None,
        "eligibility": "First or second-year graduate students enrolled in an accredited program.",
        "officialSourceUrl": "https://nsfgrfp.org",
        "registrationUrl": "https://nsfgrfp.org/apply",
        "lastVerifiedDate": "2026-11-16",
        "status": "Published",
        "reviewedBy": "ResWave Funding Desk"
    },
    {
        "id": "opp-ws-env-01",
        "type": "Workshop",
        "title": "Workshop on Remote Sensing for Urban Climate Mitigation",
        "organiser": "International Environmental Modeling League",
        "description": "Virtual workshop bringing together environmental modellers, geographers, and data scientists to evaluate urban heat island mitigation techniques.",
        "tags": ["Environmental Science", "Sensors", "Climate"],
        "startDate": "2027-02-18",
        "endDate": "2027-02-19",
        "submissionDeadline": "2027-01-10",
        "mode": "Online",
        "location": "Online via Zoom",
        "eligibility": "Researchers and practitioners in ecological modeling.",
        "officialSourceUrl": "https://envmod.org/urban-heat-2027",
        "registrationUrl": "https://envmod.org/register",
        "lastVerifiedDate": "2026-11-17",
        "status": "Published",
        "reviewedBy": "ResWave Academic Curator"
    }
]

SEED_GROUPS: List[Dict[str, Any]] = [
    {
        "id": "grp-hci-collab",
        "ownerId": "usr-admin-01",
        "title": "HCI & Cognitive Ergonomics Lab Circle",
        "description": "Community of students and researchers discussing usability experiments, cognitive load studies, and user experience methodologies.",
        "primaryDomain": "hci",
        "topics": ["Cognitive Ergonomics", "User Study", "Prototyping", "Accessibility"],
        "purpose": "Research collaboration",
        "membershipMode": "Open",
        "visibility": "Discoverable",
        "rules": "1. Respect diverse research backgrounds. 2. Cite prior literature when presenting critique. 3. No unauthorized solicitation.",
        "moderators": ["usr-admin-01"],
        "coverImageUrl": None,
        "status": "Active",
        "createdAt": "2026-11-01T08:00:00Z"
    },
    {
        "id": "grp-peer-support",
        "ownerId": "usr-admin-01",
        "title": "PhD & Early Career Researcher Peer Haven",
        "description": "A compassionate, safe community space for navigating publication rejections, supervisor discussions, thesis isolation, and work-life balance.",
        "primaryDomain": "General",
        "topics": ["PhD life", "Publication rejection", "Research stress", "Motivation"],
        "purpose": "Peer support",
        "membershipMode": "Open",
        "visibility": "Discoverable",
        "rules": "Safety Notice: This peer support group provides mutual encouragement and empathy, NOT professional or emergency clinical care. Be kind, protect personal confidentiality, and avoid medical claims.",
        "moderators": ["usr-admin-01"],
        "coverImageUrl": None,
        "status": "Active",
        "createdAt": "2026-11-01T09:00:00Z"
    }
]

EMERGENCY_SUPPORT_RESOURCES: List[Dict[str, Any]] = [
    {
        "country": "United States & Canada",
        "service": "988 Suicide & Crisis Lifeline",
        "contact": "Call or Text 988",
        "website": "https://988lifeline.org",
        "notes": "Free, confidential, available 24/7."
    },
    {
        "country": "United Kingdom",
        "service": "Samaritans UK",
        "contact": "Call 116 123",
        "website": "https://www.samaritans.org",
        "notes": "Free confidential emotional support 24/7."
    },
    {
        "country": "India",
        "service": "Tele-MANAS (Govt of India)",
        "contact": "Call 14416 or 1800-891-4416",
        "website": "https://telemanas.mohfw.gov.in",
        "notes": "Free, multi-lingual mental health counseling 24/7."
    },
    {
        "country": "International / Worldwide",
        "service": "Befrienders Worldwide Directory",
        "contact": "Find local helpline by country",
        "website": "https://www.befrienders.org",
        "notes": "Global directory of crisis centers and emotional support hotlines."
    }
]
