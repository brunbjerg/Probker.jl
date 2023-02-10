module Probker
using StatsBase
using Random

#~ I will stop now. I should start by looking at a previous git version of my code. 

#~ Or should I just check every thing to start with so I only ever call a single hands function?
#~ Yes! This is what I will do! 

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
    sorted::Matrix{Int}
    weights::Vector{Int}
    function Create_Mod_Hands(hands)
        mod = hands .% 13
        mod[mod .== 0] .= 13
        sorted = sort(mod, dims = 2, rev = true)
        return sorted
    end
    weights = [64, 32, 16, 8, 4, 2, 1]
    Hands(hands) = new(size(hands, 1), size(hands, 2), hands, Create_Mod_Hands(hands), weights)
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
    which_hands = zeros(Int64, game.players, 9)
    for _ = 1:game.simulations
        hands = Sample(game::Game)
        player_winners, player_hand = Determine_Win(hands)
        if length(player_winners) == 1
            wins_by_player[player_winners] .+= 1
            which_hands[player_winners, player_hand] .+= 1
        else
            players_in_split = 1/length(player_winners)
            split_by_player[player_winners] .+= players_in_split
            which_hands[player_winners, player_hand] .+= 1
        end
    end
    return wins_by_player/game.simulations, split_by_player/game.simulations, which_hands
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

#& I could make this a completely different way. Making a checker function and then make the checkers dispatch to the right hand function.
#& Is this better? Yes I think so. Now I am checking inside of every function. This is not necessary. As it is now there is some kind of coupling 
#& between every function for each hand function and between each hand function and its corresponding checker function. This seems like
#& I should make one checker function that checks everything. 

function Determine_Win(hands::Hands)
    determined_hand = Hands_Checker(hands)
    determined_hand(hands)

end 

abstract type Checker end

struct High_Card <: Checker end
struct Two_Kind <: Checker end
struct Two_Pairs <: Checker end
struct Three_Kind <: Checker end
struct Straight <: Checker end
struct Flush <: Checker end
struct Full_House <: Checker end
struct Four_Kind <: Checker end
struct Straight_Flush <: Checker end

#& I am now thinking alot and not coding as much. What should I do? 

#& My guts tell me that there is a very good way of during this.

function Hands_Checker(hands::Hands)
    Check_Straight_Flush(hands::Hands)  && return Straight_Flush
    Check_Four_Kind(hands::Hands)       && return Four_Kind
    Check_Full_House(hands::Hands)      && return Full_House
    Check_Flush(hands::Hands)      && return Flush
    Check_Straight(hands::Hands)      && return Straight
    Check_Three_Kind(hands::Hands)      && return Three_Kind
    Check_Two_Pair(hands::Hands)      && return Two_Pairs
    Check_Two_Kind(hands::Hands)      && return Two_Kind
    return High_Card

end

function Check_Straight_Flush(hands::Hands)
    return Check_Straight(hands) && Check_Flush(hands)
end

function Check_Four_Kind(hands::Hands)
    for player in 1:hands.players
        maximum(counts(hands.sorted[player, :])) == 4 && return true
    end
    return false
end

function Check_Full_House(hands::Hands)
    for player in 1:hands.players
        sum(sort(counts(hands.sorted[player, :]), rev = true)[1:2]) == 5 && return true
    end
    return false        
end

function Check_Two_Pair(hands::Hands)
    for player in 1:hands.players
        sum(sort(counts(hands.sorted[player, :]), rev = true)[1:2]) == 4 && return true
    end
    return false        
end

function Check_Straight(hands::Hands)
    support_function = [0, 1, 2, 3, 4, 5, 6, 7]
    for player in 1:hands.players   
        temp_hands = hands.sorted[player, :]
        if 13 in temp_hands
            push!(temp_hands, 0)
        else 
            push!(temp_hands, -1)
        end
        temp_hands .+= support_function 
        maximum(counts(temp_hands)) >= 5 && return true
    end
    return false
end


function Check_Flush(hands::Hands)
    for player in 1:hands.players
        for i in 0:3
            if count(x -> x in (1 + i*13 :13 + i*13), hands.hands[player, :]) >= 5 
                return Flush()
            end
        end
    end
    return false
end

function Check_Three_Kind(hands::Hands)
    for player in 1:hands.players
        if any(counts(hands.sorted[player, :]) .>= 3)
            return true
        end 
    end
    return false
end


function Check_Three_Kind(hands::Hands)
    for player in 1:hands.players
        if any(counts(hands.sorted[player, :]) .>= 2)
            return true
        end 
    end
    return false
end

function Cards_To_Hands(player_cards, shared_cards)
    hands = zeros(Int64, length(player_cards)÷2, 7)
    for player = 1:length(player_cards)÷2
        for card = 1:7
            if card in [1, 2]
                hands[player, card] = player_cards[(player - 1) * 2 + card]
            else
                hands[player, card] = shared_cards[card - 2]
            end
        end
    end
    return Hands(hands)
end

function High_Card(hands::Hands)
    winners = zeros(Int64, hands.players, hands.cards)
    for card = 1:hands.cards
        highest_card = 0
        for player = 1:hands.players
            if hands.sorted[player, card] == highest_card
                winners[player,card] = 1
                highest_card = hands.sorted[player, card]
            elseif hands.sorted[player, card] > highest_card
                winners[:, card] .= 0
                winners[player, card] = 1
                highest_card = hands.sorted[player, card]
            end
        end
    end
    player_scores = winners * hands.weights 
    best_hand = findmax(player_scores)[1]
    winner_players = findall(x->x == best_hand, player_scores)
    return winner_players
end

function Two_Kind(hands::Hands)
    player_scores = zeros(Int64, hands.players, 7)
    for player = 1:hands.players
        for card = 1:hands.cards
            if card != 1 && hands.sorted[player, card] == hands.sorted[player, card - 1]
                continue
            end
            if card != 7 && hands.sorted[player, card] == hands.sorted[player, card + 1] 
                player_scores[player, card] = 3000 * hands.sorted[player, card]
                player_scores[player, card + 1] = 3000 * hands.sorted[player, card]
            else 
                player_scores[player, card] = hands.weights[card] * hands.sorted[player, card]
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

function Two_Pairs(hands::Hands)
    player_scores = zeros(Int64, hands.players, 7)
    two_pairs_checker = zeros(Int64, hands.players)
    for player in 1:hands.players
        first_pair = 1
        for card in 1:hands.cards
            if card != 1 && hands.sorted[player, card] == hands.sorted[player, card - 1]
                if card == 7 && player_scores[player, card] == 0  
                    player_scores[player, card] = hands.sorted[player, card]
                end
                continue
            end
            if card != 7 && hands.sorted[player, card] == hands.sorted[player, card + 1] && two_pairs_checker[player] < 2
                pair_weight = 3000
                if first_pair == 1
                    pair_weight = 15*3000
                    first_pair = 0
                end
                player_scores[player, card] = pair_weight*hands.sorted[player, card]
                player_scores[player, card + 1] = pair_weight*hands.sorted[player, card ]
                two_pairs_checker[player] += 1            
            else
                player_scores[player, card] = hands.weights[card] * hands.sorted[player, card]
            end
        end    
    end

    sorted_scores = sort(player_scores, dims = 2, rev = true)
    for player in 1:hands.players
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
    for player in 1:hands.players
        push!(vector_summed_scores, summed_scores[player])
    end
    best_hand = findmax(vector_summed_scores)[1]
    player_winners = findall(x->x == best_hand, vector_summed_scores)
    return player_winners
end

function Three_Kind(hands::Hands)
    player_scores = zeros(Int64, hands.players, hands.cards)
    for player in 1:hands.players
        three_kind = 0
        card = 1
        while card <= hands.cards 
            if three_kind == 0 && card <= 5 && hands.sorted[player, card] == hands.sorted[player, card + 1] == hands.sorted[player, card + 2] 
                player_scores[player, card + 0] = 3000*hands.sorted[player, card + 0]
                player_scores[player, card + 1] = 3000*hands.sorted[player, card + 1]
                player_scores[player, card + 2] = 3000*hands.sorted[player, card + 2]
                three_kind = 1
                card += 2
            else
                player_scores[player, card] = hands.weights[card]*hands.sorted[player, card]
            end
            card += 1
        end
    end
    sorted_scores = sort(player_scores, dims = 2, rev = true)
    summed_scores = sum(sorted_scores[:,1:5], dims = 2)
    vector_summed_scores = []
    for player in 1:hands.players
        push!(vector_summed_scores, summed_scores[player])
    end
    best_hand = findmax(vector_summed_scores)[1]
    player_winners = findall(x->x == best_hand, vector_summed_scores)
    return player_winners
end

function Straight(hands::Hands)
    player_scores = zeros(Int64, hands.players)
    for player in 1:hands.players
        count = 1
        ace_updated_hand = copy(hands.sorted[player, :])
        if 13 in ace_updated_hand
            push!(ace_updated_hand, 0)
        end
        for card = 1:length(ace_updated_hand) - 1
            if ace_updated_hand[card] == ace_updated_hand[card + 1] + 1
                count += 1
                if count == 5
                    player_scores[player] = copy(ace_updated_hand[card])
                end
            else
                count = 1
            end
        end
    end
    best_hand = findmax(player_scores)[1]
    player_winners = findall(x -> x == best_hand, player_scores)
    return player_winners
end

""" 
If there is a flush present then the functions returns the winner(s)
"""
function Flush(hands::Hands)
    player_scores_with_suits = zeros(Int64, hands.players, hands.cards, 4)
    for player in 1:hands.players
        count_suit = zeros(Int64, 4)
        for card in 1:hands.cards
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
    for player in 1:hands.players
        for suit = 1:4
            if sum(player_scores_with_suits[player, :, suit] .> 0.5 ) >= 5
                player_scores_with_suits[player, :, suit] = 20*player_scores_with_suits[player, :, suit]
                player_scores_with_suits[player, :, setdiff(1:4, suit)] .= 0 
            end
        end
    end
    sorted_scores_with_suits = sort(player_scores_with_suits, dims = 2, rev = true)
    weighted_player_scores_with_suits = zeros(Int64, size(sorted_scores_with_suits)[1], size(sorted_scores_with_suits)[2], size(sorted_scores_with_suits)[3])
    for player in 1:hands.players 
        for card in 1:hands.cards
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
    for player in 1:hands.players
        hand_for_a_given_player = hands.sorted[player, :]
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
    for player in 1:hands.players
        for i = 1:13
            find_n_kinds = findall(x->x == i, hands.sorted[player, :])
            if length(find_n_kinds) ==  4
                player_score[player, find_n_kinds] = 10000 * hands.sorted[player, find_n_kinds]
                remaining_cards = setdiff(1:7, find_n_kinds)
                player_score[player, remaining_cards] = card_weight .* hands.sorted[player, remaining_cards]
                four_of_a_kind_checker = 1
            end
        end
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
    add_to_each_card = [0, 1, 2, 3, 4, 5, 6]
    player_score = zeros(Int64, hands.players)
    for player in 1:hands.players
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

end # module