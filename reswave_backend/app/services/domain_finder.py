"""
RESWAVE - Domain Recommendation Engine
Section 4.3: Deterministic, explainable tag matching with dynamic weight redistribution.
"""

from typing import List, Dict, Any, Tuple

DEFAULT_WEIGHTS = {
    "subjects": 0.30,
    "problems": 0.25,
    "workStyles": 0.20,
    "skills": 0.15,
    "goals": 0.10
}

IGNORED_TAGS = {"not sure", "skip", "other", ""}


def normalize_tags(tags) -> set:
    if not tags:
        return set()
    return {
        str(tag).strip().lower()
        for tag in tags
        if str(tag).strip().lower() not in IGNORED_TAGS
    }


def calculate_jaccard_overlap(
    user_tags: List[str],
    domain_tags: List[str]
) -> float:
    user_set = normalize_tags(user_tags)
    domain_set = normalize_tags(domain_tags)

    if not user_set or not domain_set:
        return 0.0

    union = user_set.union(domain_set)
    if not union:
        return 0.0

    intersection = user_set.intersection(domain_set)
    return len(intersection) / len(union)


def score_domain_against_questionnaire(
    param1: Dict[str, Any],
    param2: Dict[str, Any],
    is_exploratory: bool = False
) -> Tuple[float, List[str]]:
    # Dynamic parameter ordering support (supports both (domain, answers) and (answers, domain))
    if "subjectTags" in param1 or "keywords" in param1 or "subdomains" in param1:
        domain = param1
        answers = param2
    else:
        answers = param1
        domain = param2

    if is_exploratory:
        return 50.0, [
            "Explore this domain to discover whether it matches your interests."
        ]

    tag_mapping = {
        "subjects": "subjectTags",
        "problems": "problemTags",
        "workStyles": "workStyleTags",
        "skills": "skillTags",
        "goals": "goalTags"
    }

    answered = {}
    for key in tag_mapping:
        tags = normalize_tags(answers.get(key, []))
        if tags:
            answered[key] = tags

    # If user provided insufficient information, return honest baseline
    if len(answered) < 2 and not answers.get("topicInMind"):
        return 50.0, [
            "Explore this domain to discover your research interests."
        ]

    # Proportional weight redistribution over answered questions
    total_weight = sum(DEFAULT_WEIGHTS[k] for k in answered)
    if total_weight == 0:
        total_weight = 1.0

    reasons = []
    total_score = 0.0

    for key, domain_key in tag_mapping.items():
        if key not in answered:
            continue

        user_tags = answered[key]
        domain_tags = normalize_tags(domain.get(domain_key, []))
        overlap = user_tags.intersection(domain_tags)

        weight = DEFAULT_WEIGHTS[key] / total_weight
        if user_tags and domain_tags:
            match_ratio = len(overlap) / len(user_tags) if overlap else 0.0
            jaccard = calculate_jaccard_overlap(list(user_tags), list(domain_tags))
            score_dim = (match_ratio * 0.7) + (jaccard * 0.3)
        else:
            score_dim = 0.0

        total_score += score_dim * weight

        if overlap:
            matched = ", ".join(sorted(overlap))
            reasons.append(
                f"Matches your {key} interests: {matched.title()}."
            )

    # Optional free-text topic matching
    topic = (answers.get("topicInMind") or "").strip()
    if len(topic) > 2:
        searchable = []
        for key in ["keywords", "subdomains"]:
            searchable.extend(domain.get(key, []))

        topic_words = {
            word.lower().strip(".,!?")
            for word in topic.split()
            if len(word) > 3
        }

        searchable_text = " ".join(str(item).lower() for item in searchable)
        matched_words = [word for word in topic_words if word in searchable_text]

        if matched_words:
            total_score = min(1.0, total_score + 0.15)
            reasons.append(
                f"Your topic relates to this domain through: {', '.join(matched_words)}."
            )

    final_score = round(total_score * 100, 1)

    if not reasons:
        reasons.append(
            "This domain may offer an interdisciplinary research direction."
        )

    return final_score, reasons


def determine_fit_band(
    score: float,
    is_exploratory: bool = False
) -> str:
    if is_exploratory:
        return "Explore"
    if score >= 65:
        return "Strong"
    if score >= 35:
        return "Possible"
    return "Explore"
