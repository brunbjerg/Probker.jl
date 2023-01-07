module Probker
using StatsBase, Random

struct Game
    players::Int64
    cards::Vector{Int64}
    pile::Vector{Int64}
    samples::Int64
    simulations::Int64
    Game(players, cards, simulations) = 
    new(players, cards, setdiff(collect(1:52), cards), sum(x -> x == 0, cards), simulations) 
end

struct Hands
    players::Int 
    cards::Int
    hands::Matrix{Int}
    sorted_mod_hands::Matrix{Int}
    weights::Vector{Int}
end

export Simulate
export Determine_Win
export Sample
export High_Card, Two_Kind, Two_Pairs, Three_Kind, Straight, Flush, Full_House, Four_Kind, Straight_Flush
export Card_Duplication
export Cards_To_Hands
export Game
export Hands

function Simulate(game::Game)
    wins_by_player = zeros(Int64, game.players)
    split_by_player = zeros(Float64, game.players)
    for _ = 1:game.simulations
        #& player cards and shared cards should be refactored. Into a struct
        hands = Sample(game::Game)
        player_winners = Determine_Win(hands)
        if length(player_winners) == 1
            wins_by_player[player_winners] .+= 1
        else
            players_in_split = 1/length(player_winners)
            split_by_player[player_winners] .+= players_in_split
        end
    end
    return wins_by_player/game.simulations, split_by_player/game.simulations
end


function Sample(game::Game)
    j = 0
    sampled_cards = sample(game.pile, game.samples, replace = false)
    cards = copy(game.cards)
    for i in eachindex(game.cards)
        if cards[i] == 0
            j += 1
            cards[i] = sampled_cards[j]
        end
    end
    return Cards_To_Hands(cards[1:game.players*2], cards[game.players*2+1:end])
end

function Determine_Win(hands::Hands)
    determine_hand = (Straight_Flush, Four_Kind, Full_House, Flush, Straight, Three_Kind, Two_Pairs, Two_Kind, High_Card)
    for fun in determine_hand
        if fun(hands) == "non-existent"
            continue
        else
            return fun(hands)
        end
    end
end 

function Cards_To_Hands(player_cards, shared_cards)
    hands_for_each_player = zeros(Int64, length(player_cards)÷2, 7)
    for player = 1:length(player_cards)÷2
        for card = 1:7
            if card in [1,2]
                hands_for_each_player[player,card] = player_cards[(player - 1)*2 + card]
            else
                hands_for_each_player[player,card] = shared_cards[card-2]
            end
        end
    end
    modulus_13_hands = hands_for_each_player .% 13
    modulus_13_hands[modulus_13_hands .== 0] .= 13
    sorted_hands = sort(modulus_13_hands, dims = 2, rev = true)
    weights = [64, 32, 16, 8, 4, 2, 1]
    return Hands(length(player_cards)÷2, 7, hands_for_each_player, sorted_hands, weights)
end

function High_Card(hands::Hands)
    winners = zeros(Int64, hands.players, hands.cards)
    for card = 1:hands.cards
        highest_card = 0
        for player = 1:hands.players
            if hands.sorted_mod_hands[player, card] == highest_card
                winners[player,card] = 1
                highest_card = hands.sorted_mod_hands[player, card]
            elseif hands.sorted_mod_hands[player, card] > highest_card
                winners[:     ,card] .= 0
                winners[player,card] = 1
                highest_card = hands.sorted_mod_hands[player, card]
            end
        end
    end
    player_scores = winners * hands.weights 
    best_hand = findmax(player_scores)[1]
    winner_players = findall(x->x == best_hand, player_scores)
    return winner_players
end

function Two_Kind(hands::Hands)
    if Check_For_Two_Kind(hands.hands)
        return "non-existent"
    end
    player_scores = zeros(Int64, hands.players, 7)
    for player = 1:hands.players
        for card = 1:hands.cards
            if card != 1 && hands.sorted_mod_hands[player, card] == hands.sorted_mod_hands[player, card - 1]
                continue
            end
            if card != 7 && hands.sorted_mod_hands[player, card] == hands.sorted_mod_hands[player, card + 1] 
                player_scores[player, card] = 3000*hands.sorted_mod_hands[player, card]
                player_scores[player, card + 1] = 3000*hands.sorted_mod_hands[player, card]
                two_of_a_kind_checker = 1
            else 
                player_scores[player, card] = hands.weights[card] * hands.sorted_mod_hands[player, card]
            end
        end
    end
    sorted_score = sort(player_scores, dims = 2, rev = true)
    summed_score = sum(sorted_score[:, 1:5], dims = 2)
    vector_summed_score = []
    for player = 1:hands.players
        push!(vector_summed_score,summed_score[player, 1])
    end
    best_hand = findmax(vector_summed_score)[1]
    winner_players = findall(x->x == best_hand, vector_summed_score)   
    return winner_players 
end

function Check_For_Two_Kind(hands_for_each_player)
    mod_hands = hands_for_each_player .% 13
    for i = 1:length(hands_for_each_player[:,1])
        if length(mod_hands[i,:]) == length(unique(mod_hands[i,:]))
            return true
        end
    end
    return false
end

function Two_Pairs(hands::Hands)
    if Check_Two_Pairs(hands.hands)
        return "non-existent"
    end
    player_scores = zeros(Int64, hands.players, 7)
    two_pairs_checker = zeros(Int64, hands.players)
    for player in hands.players
        first_pair = 1
        for card in hands.cards
            if card != 1 && hands.sorted_mod_hands[player, card] == hands.sorted_mod_hands[player, card - 1]
                if card == 7 && player_scores[player, card] == 0  
                    player_scores[player, card] = hands.sorted_mod_hands[player, card]
                end
                continue
            end
            if card != 7 && hands.sorted_mod_hands[player, card] == hands.sorted_mod_hands[player, card + 1] && two_pairs_checker[player] < 2
                pair_weight = 3000
                if first_pair == 1
                    pair_weight = 15*3000
                    first_pair = 0
                end
                player_scores[player, card] = pair_weight*hands.sorted_mod_hands[player, card]
                player_scores[player, card + 1] = pair_weight*hands.sorted_mod_hands[player, card ]
                two_pairs_checker[player] += 1            
            else
                player_scores[player, card] = hands.weights[card] * hands.sorted_mod_hands[player, card]
            end
        end    
    end

    sorted_scores = sort(player_scores, dims = 2, rev = true)
    for player in hands.players
        pair_count = 0
        first_card_of_pair = 0
        for card in setdiff!(collect(1:hands.cards), 7)
            if sorted_scores[player, card] == sorted_scores[player, card + 1]
                pair_count += 1
                first_card_of_pair = card
            end
        end
        if pair_count == 1
            sorted_scores[player,first_card_of_pair] = sorted_scores[player, first_card_of_pair]/15
            sorted_scores[player,first_card_of_pair + 1] = sorted_scores[player, first_card_of_pair + 1]/15
        end
    end
    summed_scores = sum(sorted_scores[:,1:5], dims = 2)
    vector_summed_scores = []
    for player in hands.players
        push!(vector_summed_scores, summed_scores[player])
    end
    best_hand = findmax(vector_summed_scores)[1]
    player_winners = findall(x->x == best_hand, vector_summed_scores)
    return player_winners
end

function Three_Kind(hands::Hands)
    player_scores = zeros(Int64, hands.players, hands.cards)
    exsistent_three_kind = 0
    for player in 1:hands.players
        three_kind = 0
        card = 1
        while card <= hands.cards 
            if three_kind == 0 && card <= 5 && hands.sorted_mod_hands[player, card] == hands.sorted_mod_hands[player, card + 1] == hands.sorted_mod_hands[player, card + 2] 
                player_scores[player, card + 0] = 3000*hands.sorted_mod_hands[player, card + 0]
                player_scores[player, card + 1] = 3000*hands.sorted_mod_hands[player, card + 1]
                player_scores[player, card + 2] = 3000*hands.sorted_mod_hands[player, card + 2]
                three_kind = 1
                exsistent_three_kind = 1
                card += 2
            else
                player_scores[player, card] = hands.weights[card]*hands.sorted_mod_hands[player, card]
            end
            card += 1
        end
    end
    if exsistent_three_kind == 0
        return "non-existent"
    end
    sorted_scores = sort(player_scores, dims = 2, rev = true)
    summed_scores = sum(sorted_scores[:,1:5], dims = 2)
    vector_summed_scores = []
    for player in hands.players
        push!(vector_summed_scores, summed_scores[player])
    end
    best_hand = findmax(vector_summed_scores)[1]
    player_winners = findall(x->x == best_hand, vector_summed_scores)
    return player_winners
end

function Checker_Three_Of_A_Kind()
    mod_hands = hands_for_each_player .% 13
    for i = 1:length(hands_for_each_player[:,1])
        if mode(mod_hands[i,:]) == 3
            return false
        end
    end
    return true
end

function Straight(hands::Hands)
    straight_check = 0
    player_scores = zeros(Int64, hands.players)
    for player in hands.players
        count = 1
        ace_updated_hand = hands.sorted_mod_hands[player,:]
        if 13 in ace_updated_hand
            pushfirst!(ace_updated_hand, 0)
        end
        for card = 1:length(ace_updated_hand) - 1
            if ace_updated_hand[card] == ace_updated_hand[card+1] - 1
                count += 1
                if count == 5
                    player_scores[player] = ace_updated_hand[card]
                    straight_check = 1
                end
            else
                count = 1
            end
        end
    end
    if straight_check == 0 
        return "non-existent"
    end
    best_hand = findmax(player_scores)[1]
    player_winners = findall(x->x == best_hand, player_scores)
    return player_winners
end

function Flush(hands::Hands)
    flush_checker = 0
    player_scores_with_suits = zeros(Int64, hands.players, hands.cards, 4)
    for player in hands.players
        count_suit = zeros(Int64, 4)
        for card in hands.cards
            if hands.hands[player, card] <= 13
                player_scores_with_suits[player, card, 1] = Card_To_Kind(hands.hands[player, card])
            elseif hands.hands[player, card] <= 26
                player_scores_with_suits[player, card, 2] = Card_To_Kind(hands.hands[player, card])
            elseif hands.hands[player, card] <= 39
                player_scores_with_suits[player, card, 3] = Card_To_Kind(hands.hands[player, card])
            elseif hands.hands[player, card] <= 52
                player_scores_with_suits[player, card, 4] = Card_To_Kind(hands.hands[player, card])
            end
        end
    end
    for player in hands.players
        for suit = 1:4
            if sum(player_scores_with_suits[player, :, suit] .> 0.5 ) >= 5
                player_scores_with_suits[player, :, suit] = 20*player_scores_with_suits[player, :, suit]
                player_scores_with_suits[player, :, setdiff(1:4, suit)] .= 0 
                flush_checker = 1
            end
        end
    end
    if flush_checker == 0
        return "non-existent"
    end
    sorted_scores_with_suits = sort(player_scores_with_suits, dims = 2, rev = true)
    weighted_player_scores_with_suits = zeros(Int64, size(sorted_scores_with_suits)[1], size(sorted_scores_with_suits)[2], size(sorted_scores_with_suits)[3])
    for player in hands.players 
        for card in hands.cards
            for suit = 1:4
                weighted_player_scores_with_suits[player, card, suit] = hands.weights[card]*sorted_scores_with_suits[player, card, suit]
            end
        end
    end
    player_scores = sum(weighted_player_scores_with_suits[:, card, suit] for card = 1:5 for suit = 1:4)
    best_hand = findmax(player_scores)[1]
    player_winners = findall(x->x == best_hand, player_scores)
    return player_winners 
end

function Full_House(hands::Hands)
    player_score = zeros(Int64, hands.players)
    full_house_checker = 0
    for player in hands.players
        hand_for_a_given_player = hands.sorted_mod_hands[player, :]
        first_time_three_kinds = 1
        first_time_two_kinds = 1
        for i in 13:-1:1
            try_finding_three = findall(x->x == i, hand_for_a_given_player)
            if length(try_finding_three) == 3 && first_time_three_kinds == 1
                first_time_three_kinds = 0
                for j in setdiff(13:-1:1 , i)
                    try_finding_two = findall(x->x == j, hand_for_a_given_player)
                    if length(try_finding_two) >= 2 && first_time_two_kinds == 1
                        first_time_two_kinds = 0
                        player_score[player] += hand_for_a_given_player[try_finding_three[1]]*14
                        player_score[player] += hand_for_a_given_player[try_finding_two[1]]
                        full_house_checker = 1
                    end
                end
            end
        end
    end
    if full_house_checker == 0
        return "non-existent"
    end
    best_hand = findmax(player_score)[1]
    player_winners = findall(x->x == best_hand, player_score)
    winners = []
    for i = eachindex(player_winners)
        push!(winners, player_winners[i][1])    
    end
    return winners
end

function Four_Kind(hands::Hands)
    card_weight = [225, 15, 1]
    four_of_a_kind_checker = 0
    player_score = zeros(Int64, hands.players, hands.cards)
    for player in hands.players
        for i = 1:13
            find_n_kinds = findall(x->x ==i, hands.sorted_mod_hands[player, :])
            if length(find_n_kinds) ==  4
                player_score[player, find_n_kinds] = 10000*hands.sorted_mod_hands[player, find_n_kinds]
                remaining_cards = setdiff(1:7, find_n_kinds)
                player_score[player, remaining_cards] = card_weight .* hands.sorted_mod_hands[player, remaining_cards]
                four_of_a_kind_checker = 1
            end
        end
    end
    if four_of_a_kind_checker == 0
        return "non-existent"
    end
    sorted_player_scores = sort(player_score, dims = 2, rev = true)
    summed_player_scores = sum(sorted_player_scores[:,1:5], dims = 2)
    best_hand = findmax(summed_player_scores)[1]
    player_winners = findall(x->x == best_hand, summed_player_scores)
    winners = []
    for i = eachindex(player_winners)
        push!(winners, player_winners[i][1])    
    end
    return winners
end

function Straight_Flush(hands::Hands)  
    straight_flush_checker = 0
    add_to_each_card = [0, 1, 2, 3, 4, 5, 6]
    player_score = zeros(Int64, hands.players)
    for player in hands.players
        player_hand_original = hands.hands[player, :]
        flush, suit, indices = Check_Flush(player_hand_original) 
        if flush
            sorted_flush_hand = sort(player_hand_original[indices], rev = true)
            straight_adjusted_hand = add_to_each_card[1:length(indices)] .+ sorted_flush_hand
            straight_and_Modulus_adjusted_hand = straight_adjusted_hand .% 13
            straight_and_Modulus_adjusted_hand[straight_and_Modulus_adjusted_hand .== 0] .= 13
            for i = 1:13
                values = findall(x->x == i, straight_and_Modulus_adjusted_hand)
                if length(values) >= 5
                    straight_flush_checker = 1
                    player_score[player] = straight_and_Modulus_adjusted_hand[1][1] 
                end
            end
        end

    end
    
    if straight_flush_checker == 0
        return "non-existent"
    end
    
    best_hand = findmax(player_score)[1]
    player_winners = findall(x->x == best_hand, player_score)
    
    return player_winners
end

function Check_Flush(player_hand)
    if length(findall(x->x in 1:13, player_hand)) >= 5
        return true, 1, findall(x->x in 1:13, player_hand)
    elseif length(findall(x->x in 14:26, player_hand)) >= 5
        return true, 2, findall(x->x in 14:26, player_hand)
    elseif length(findall(x->x in 27:39, player_hand)) >= 5
        return true, 3, findall(x->x in 27:40, player_hand)
    elseif length(findall(x->x in 40:52, player_hand)) >= 5
        return true, 4, findall(x->x in 40:52, player_hand)
    end
    return false, 0, 0
end

function Card_To_Kind(card)
    kind = card % 13
    if kind == 0
        kind = 13
    end
    return kind
end

function Check_Two_Pairs(hands_for_each_player)
    mod_hands = hands_for_each_player .% 13
    for i = 1:length(hands_for_each_player[:,1])
        if 7 == 2 + length(unique(mod_hands[i,:]))
            return false
        end
    end
    return true
end




end # module