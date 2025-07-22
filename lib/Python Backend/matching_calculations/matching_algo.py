




def normalize_answer(answer, reverse=False, min_val=1, max_val=7):
    if not reverse:
        return (answer - min_val) / (max_val - min_val)
    else:
        return (max_val - answer) / (max_val - min_val)



def get_trait_means(quiz_answers, reverse_keys, n_traits=5, min_val=1, max_val=7):
    """quiz_answers: dict {idx: answer}
       reverse_keys: set of idx that are reverse scored
       Returns: list of length n_traits, each entry 0–1"""
    trait_sums = [0.0] * n_traits
    trait_counts = [0] * n_traits

    for idx, ans in quiz_answers.items():
        trait = idx % n_traits
        is_reverse = idx in reverse_keys
        norm = normalize_answer(ans, reverse=is_reverse, min_val=min_val, max_val=max_val)
        trait_sums[trait] += norm
        trait_counts[trait] += 1

    # Avoid division by zero
    trait_means = [trait_sums[i] / trait_counts[i] if trait_counts[i] > 0 else 0.5 for i in range(n_traits)]
    return trait_means  # [O, C, E, A, N]

def ocean_compatibility(userA, userB, weights=None):
    """userA, userB: vectors [O, C, E, A, N], each 0–1 floats
       weights: list of 5 floats, sum to 1.0"""
    if weights is None:
        weights = [0.2] * 5
    dist_sq = sum(w * (a - b) ** 2 for w, a, b in zip(weights, userA, userB))
    score = 1 - dist_sq ** 0.5
    return score

# Example usage:
# userA_answers = {0: 5, 1: 2, ...}  # your stored dictionary
# reverse_keys = {1, 3, 5, ...}  # set of indices that are reverse scored

# userA_traits = get_trait_means(userA_answers, reverse_keys)
# userB_traits = get_trait_means(userB_answers, reverse_keys)
# score = ocean_compatibility(userA_traits, userB_traits)
