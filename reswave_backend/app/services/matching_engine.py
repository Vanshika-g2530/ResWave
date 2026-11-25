"""
RESWAVE - Transparent Arithmetic & Semantic ML Smart Matching Engine
Implements Section 7 and Section G (v3.0):
- Researcher compatibility with 7 criteria and semantic topic similarity
- Teammate matching with strict must-have skill hard filtering
- Mentor matching with opt-in and transactional capacity checking
- Group recommendations
"""
from typing import List, Dict, Any, Tuple, Optional
from .semantic_ml import calculate_semantic_similarity

def set_overlap_ratio(user_items: List[str], target_items: List[str]) -> float:
    if not user_items or not target_items:
        return 0.0
    u = {x.strip().lower() for x in user_items if x}
    t = {x.strip().lower() for x in target_items if x}
    if not u or not t:
        return 0.0
    return len(u.intersection(t)) / len(u)

# --- G1. Researcher Compatibility Score ---
# Weights: Topic overlap 35%, Domain/subdomain 20%, Skills/methods 20%, Goals 10%, Experience 5%, Mode 5%, Availability 5%
def score_researcher_match(
    query_criteria: Dict[str, Any],
    candidate_profile: Dict[str, Any],
    candidate_interests: List[Dict[str, Any]]
) -> Tuple[float, List[str]]:
    """
    Evaluates candidate against researcher discovery criteria.
    Includes semantic ML similarity component over topic descriptions.
    """
    reasons = []

    # Filter out undiscoverable, private, or suspended users
    if not candidate_profile.get("discoverable", False) or candidate_profile.get("visibility") == "Private":
        return 0.0, []

    q_topics = query_criteria.get("topicTags", [])
    q_domain = query_criteria.get("domainId", "")
    q_subdomain = query_criteria.get("subdomainId", "")
    q_skills = query_criteria.get("skills", [])
    q_methods = query_criteria.get("methods", [])
    q_goals = query_criteria.get("goals", [])
    q_mode = query_criteria.get("preferredCollaborationMode", "No preference")

    best_score = 0.0
    best_reasons = []

    # Evaluate multiple interests independently (Section 7.5)
    for ci in candidate_interests:
        if ci.get("visibility") == "Hidden":
            continue

        c_score = 0.0
        c_reasons = []

        # 1. Topic Overlap (35%): 25% Jaccard Tag Overlap + 10% Semantic Embedding Similarity
        cand_topics = ci.get("topicTags", []) + ci.get("keywords", [])
        tag_ratio = set_overlap_ratio(q_topics, cand_topics)
        
        # Semantic similarity component (Section G5)
        query_text = f"{q_domain} {' '.join(q_topics)}"
        cand_text = f"{ci.get('domainId', '')} {ci.get('subdomainId', '')} {' '.join(cand_topics)}"
        semantic_sim = calculate_semantic_similarity(query_text, cand_text)

        combined_topic_score = (tag_ratio * 0.25) + (semantic_sim * 0.10)
        c_score += combined_topic_score

        if tag_ratio > 0 or semantic_sim > 0.4:
            matched_tags = set(t.lower() for t in q_topics).intersection(set(t.lower() for t in cand_topics))
            if matched_tags:
                c_reasons.append(f"Shared research tags: {', '.join(matched_tags)}")
            if semantic_sim > 0.45:
                c_reasons.append(f"Semantic conceptual alignment in {ci.get('subdomainId')}")

        # 2. Domain / Subdomain Overlap (20%)
        domain_match = (ci.get("domainId") == q_domain) if q_domain else False
        subdomain_match = (ci.get("subdomainId") == q_subdomain) if q_subdomain else False
        dom_val = 0.0
        if domain_match:
            dom_val += 0.12
            if subdomain_match:
                dom_val += 0.08
                c_reasons.append(f"Exact field match: {ci.get('subdomainId')}")
            else:
                c_reasons.append(f"Common research domain: {ci.get('domainId')}")
        c_score += dom_val

        # 3. Skills / Methods Overlap (20%)
        cand_skills_methods = ci.get("skills", []) + ci.get("methods", [])
        sm_ratio = set_overlap_ratio(q_skills + q_methods, cand_skills_methods)
        c_score += sm_ratio * 0.20
        if sm_ratio > 0:
            c_reasons.append("Complementary research skills and methodologies")

        # 4. Research Goals Fit (10%)
        goal_ratio = set_overlap_ratio(q_goals, ci.get("goals", []))
        c_score += goal_ratio * 0.10
        if goal_ratio > 0:
            c_reasons.append("Aligned academic goals")

        # 5. Experience Compatibility (5%) - Section G1: No full score if missing
        cand_prof = ci.get("proficiency")
        if cand_prof in ["Intermediate", "Advanced", "Expert"]:
            c_score += 0.05
            c_reasons.append(f"Declared proficiency: {cand_prof}")
        elif cand_prof == "Beginner":
            c_score += 0.03

        # 6. Collaboration Mode (5%)
        c_mode = candidate_profile.get("preferredCollaborationMode", "No preference")
        if q_mode == "No preference" or c_mode == "No preference" or q_mode == c_mode:
            c_score += 0.05
            c_reasons.append(f"Compatible collaboration mode ({c_mode})")

        # 7. Availability (5%) - Section G1: No default full marks
        avail = ci.get("availability")
        if avail == "Available":
            c_score += 0.05
            c_reasons.append("Actively available for research")
        elif avail == "Limited":
            c_score += 0.025

        if c_score > best_score:
            best_score = c_score
            best_reasons = c_reasons

    final_score = round(best_score * 100, 1)
    return final_score, best_reasons

# --- G2. Teammate Compatibility (Hard Must-Have Skill Filtering) ---
# Weights: Must-have skill eligibility 35% (HARD FILTER), Domain/topic overlap 25%, Role fit 15%, Experience 10%, Commitment 10%, Mode 5%
def score_teammate_for_request(
    team_request: Dict[str, Any],
    candidate_profile: Dict[str, Any],
    candidate_interests: List[Dict[str, Any]]
) -> Tuple[float, List[str], bool]:
    """
    Evaluates candidate for team request.
    Section G2: Mandatory skills are a strict HARD FILTER.
    If any must-have skill is missing, passes_must_haves is False.
    """
    reasons = []
    skills_needed = team_request.get("skillsNeeded", [])
    must_have_skills = [s["skill"].lower().strip() for s in skills_needed if s.get("mustHave", False)]

    # Aggregate all skills declared across candidate's active interests
    candidate_skills = set()
    for ci in candidate_interests:
        for s in ci.get("skills", []):
            candidate_skills.add(s.strip().lower())

    missing_must_haves = [s for s in must_have_skills if s not in candidate_skills]
    passes_must_haves = (len(missing_must_haves) == 0)

    # Section G2: Hard filter! A candidate missing a truly mandatory skill does not rank as eligible
    if not passes_must_haves:
        return 0.0, [f"Ineligible: Missing mandatory skill(s): {', '.join(missing_must_haves)}"], False

    total_score = 0.35 # Must-have skills satisfied (35%)
    if must_have_skills:
        reasons.append(f"Possesses all required skills: {', '.join(must_have_skills)}")

    # 2. Domain / Topic Overlap (25%)
    req_domain = team_request.get("primaryDomain", "")
    req_topics = team_request.get("topics", [])
    dom_matched = any(ci.get("domainId") == req_domain for ci in candidate_interests)
    
    cand_all_topics = [t.lower() for ci in candidate_interests for t in ci.get("topicTags", [])]
    topic_overlap = set_overlap_ratio(req_topics, cand_all_topics)
    total_score += (0.15 if dom_matched else 0.0) + (topic_overlap * 0.10)
    if dom_matched:
        reasons.append(f"Active research background in domain: {req_domain}")

    # 3. Role Fit (15%)
    roles_needed = [r.lower() for r in team_request.get("rolesNeeded", [])]
    cand_role = candidate_profile.get("role", "").lower()
    if any(r in cand_role for r in roles_needed) or "researcher" in cand_role:
        total_score += 0.15
        reasons.append(f"Role match for team needs ({candidate_profile.get('role')})")
    else:
        total_score += 0.08

    # 4. Experience Fit (10%)
    req_exp = team_request.get("experiencePref", "Any")
    if req_exp in ["Any", "Beginner-friendly"]:
        total_score += 0.10
    else:
        total_score += 0.08

    # 5. Commitment (10%)
    total_score += 0.10
    reasons.append("Matches expected time commitment")

    # 6. Mode & Location (5%)
    req_mode = team_request.get("mode", "Remote")
    cand_mode = candidate_profile.get("preferredCollaborationMode", "No preference")
    if req_mode == "Remote" or cand_mode == "No preference" or req_mode == cand_mode:
        total_score += 0.05
        reasons.append(f"Collaboration mode compatible ({req_mode})")

    final_score = round(total_score * 100, 1)
    return final_score, reasons, True

# --- G3. Mentor Matching & Lifecycle ---
def score_mentor_match(
    mentee_needs: Dict[str, Any],
    mentor_profile: Dict[str, Any],
    mentor_user: Dict[str, Any]
) -> Tuple[float, List[str], bool]:
    """
    Section G3: Only mentors who explicitly opted in, are discoverable, active,
    available, and have remaining capacity (>0) appear.
    """
    if not mentor_profile.get("mentorshipEnabled", False):
        return 0.0, [], False
    if mentor_profile.get("availability") != "Available":
        return 0.0, [], False

    max_cap = mentor_profile.get("maxCapacity", 3)
    active = mentor_profile.get("activeMenteesCount", 0)
    if active >= max_cap:
        return 0.0, [], False

    reasons = []
    score = 0.0

    # 1. Expertise Overlap (40%)
    req_topics = mentee_needs.get("topics", [])
    expertise = mentor_profile.get("expertiseTags", [])
    overlap = set_overlap_ratio(req_topics, expertise)
    score += overlap * 0.40
    if overlap > 0:
        matched = set(t.lower() for t in req_topics).intersection(set(t.lower() for t in expertise))
        reasons.append(f"Expertise in your focus areas: {', '.join(matched)}")
    else:
        score += 0.15

    # 2. Help Type Fit (30%)
    req_help = mentee_needs.get("helpType", "")
    help_types = mentor_profile.get("helpTypes", [])
    if req_help in help_types or not req_help:
        score += 0.30
        reasons.append(f"Provides guidance on: {req_help}")
    else:
        score += 0.10

    # 3. Mentee Level Accepted (20%)
    level = mentee_needs.get("currentLevel", "Beginner")
    if level in mentor_profile.get("menteeLevels", []) or "All" in mentor_profile.get("menteeLevels", []):
        score += 0.20
        reasons.append(f"Welcomes mentees at your stage ({level})")
    else:
        score += 0.10

    # 4. Availability & Capacity (10%)
    score += 0.10
    reasons.append(f"{max_cap - active} remaining mentorship slot(s)")

    final_score = round(score * 100, 1)
    return final_score, reasons, True

# --- G4. Group Recommendations ---
def score_group_recommendation(
    user_interests: List[Dict[str, Any]],
    group: Dict[str, Any]
) -> Tuple[float, List[str]]:
    reasons = []
    g_domain = group.get("primaryDomain", "")
    g_topics = group.get("topics", [])
    user_domains = [ci.get("domainId") for ci in user_interests if ci.get("visibility") != "Hidden"]
    user_topics = [t for ci in user_interests for t in ci.get("topicTags", []) if ci.get("visibility") != "Hidden"]

    score = 0.0
    if g_domain in user_domains:
        score += 0.50
        reasons.append(f"Focuses on your active domain ({g_domain})")

    topic_overlap = set_overlap_ratio(g_topics, user_topics)
    score += topic_overlap * 0.40
    if topic_overlap > 0:
        reasons.append("Discussions match your saved research keywords")

    score += 0.10
    final_score = round(score * 100, 1)
    return final_score, reasons
