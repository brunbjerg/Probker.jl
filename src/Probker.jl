module Probker

#########################################################
#####                LOAD DEPENDENCIES              #####
#########################################################

using StatsBase
using Random

#########################################################
#####                 DEFINE TYPES                  #####
#########################################################

struct Game
    players::Int
    cards::Vector{Int}
    pile::Vector{Int}
    folded::Vector{Int}
    samples::Int
    simulations::Int
    Game(players, cards, folded, simulations) = 
    new(players, cards, setdiff(collect(1:52), cards, folded), folded, sum(x -> x == 0, cards), simulations) 
end

struct Hands
    players::Vector{Int} 
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
    Hands(hands, folded) = new([i for i in 1:size(hands, 1) if folded[i * 2 - 1] != -1], size(hands, 2), hands, Create_Mod_Hands(hands), weights)
end

#########################################################
#####                EXPORT FUNCTIONS               #####
#########################################################

export Simulate
export Hands_Checker
export Sample

#TODO make single function and use types
export High_Card, 
       Two_Kind, 
       Two_Pairs, 
       Three_Kind, 
       Straight, 
       Flush, 
       Full_House, 
       Four_Kind, 
       Straight_Flush

export Cards_To_Hands
export Game
export Hands

#########################################################
#####                 INCLUDE FILES                 #####
#########################################################

include("Auxilary_Functions.jl")
include("Checker_Functions.jl")

#########################################################
#####                  SOURCE CODE                  #####
#########################################################

function Simulate(game::Game)
    #& Here we have to change the function so that no matter what 
    #& we will get a player that has folded cannot win.

    #& We have to remove the player from the calculations before it goes to the 
    #& checker. The question is whether the code can handle a single player.
    #& I do not think that should be a problem. If it is we will take that
    #& later. The folded cards have already been removed.

    wins_by_player = zeros(Int, game.players)
    split_by_player = zeros(Float64, game.players)
    which_hands = zeros(Int, game.players, 9)
    for _ = 1:game.simulations
        hands = Sample(game::Game)
        player_winners, player_hand = Hands_Checker(hands)
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
    #& The change should be done in here I think
    j = 0
    sampled_cards = sample(game.pile, game.samples, replace = false)
    cards = copy(game.cards)
    for i in eachindex(game.cards)
        if cards[i] == 0
            j += 1
            cards[i] = sampled_cards[j]
        end
    end
    return Cards_To_Hands(cards[1:game.players*2], cards[game.players*2+1:end], game.folded)
end

function Hands_Checker(hands::Hands)
    Check_Straight_Flush(hands::Hands)  && return Straight_Flush(hands::Hands), 1
    Check_Four_Kind(hands::Hands)       && return Four_Kind(hands::Hands), 2
    Check_Full_House(hands::Hands)      && return Full_House(hands::Hands), 3
    Check_Flush(hands::Hands)           && return Flush(hands::Hands), 4
    Check_Straight(hands::Hands)        && return Straight(hands::Hands), 5
    Check_Three_Kind(hands::Hands)      && return Three_Kind(hands::Hands), 6
    Check_Two_Pair(hands::Hands)        && return Two_Pairs(hands::Hands), 7
    Check_Two_Kind(hands::Hands)        && return Two_Kind(hands::Hands), 8
    return High_Card(hands::Hands), 9
end

function High_Card(hands::Hands)
    winners = zeros(Int, maximum(hands.players), hands.cards)
    for card = 1:hands.cards
        highest_card = 0
        for player = hands.players
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

#& I have a feeling that this code can be written much nicer! I want more practise! I feel a desire to keep up the work.

function Two_Kind(hands::Hands)
    player_scores = zeros(Int, maximum(hands.players), 7)
    for player = hands.players
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

    #& Using this new notation we cannot push anymore since the folded play is never added that means that we will shift an index and then not get
    #& the right player. This should be a simple fix. 
    vector_summed_score = zeros(Int, maximum(hands.players))
    for player in hands.players
        vector_summed_score[player] = summed_score[player, 1]
    end
    #! Change this
    best_hand = findmax(vector_summed_score)[1]
    winner_players = findall(x->x == best_hand, vector_summed_score)   

    return winner_players 
end

function Two_Pairs(hands::Hands)
    #& This cannot solve our problem. The size is sometimes one where we want to access player two. We need to keep 
    player_scores = zeros(Int, maximum(hands.players), 7)
    two_pairs_checker = zeros(Int, maximum(hands.players))
    for player in hands.players
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
                    pair_weight = 15 * 3000
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
    summed_score = sum(sorted_scores[:,1:5], dims = 2)
    vector_summed_score = zeros(Int, maximum(hands.players))
    for player in hands.players
        vector_summed_score[player] = summed_score[player, 1]
    end
    best_hand = findmax(vector_summed_score)[1]
    player_winners = findall(x->x == best_hand, vector_summed_score)

    return player_winners
end

function Three_Kind(hands::Hands)
    player_scores = zeros(Int, maximum(hands.players), hands.cards)
    for player in hands.players
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
    summed_score = sum(sorted_scores[:,1:5], dims = 2)
    vector_summed_score = zeros(Int, maximum(hands.players))
    for player in hands.players
        vector_summed_score[player] = summed_score[player, 1]
    end
    best_hand = findmax(vector_summed_score)[1]
    player_winners = findall(x->x == best_hand, vector_summed_score)

    return player_winners
end

function Straight(hands::Hands)
    player_scores = zeros(Int, maximum(hands.players))
    for player in hands.players
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
    println(@__LINE__, "  " , player_winners)

    return player_winners
end

function Flush(hands::Hands)
    player_scores_with_suits = zeros(Int, maximum(hands.players), hands.cards, 4)
    for player in hands.players
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
    for player in hands.players
        for suit = 1:4
            if sum(player_scores_with_suits[player, :, suit] .> 0.5 ) >= 5
                player_scores_with_suits[player, :, suit] = 20 * player_scores_with_suits[player, :, suit]
                player_scores_with_suits[player, :, setdiff(1:4, suit)] .= 0 
            end
        end
    end
    sorted_scores_with_suits = sort(player_scores_with_suits, dims = 2, rev = true)
    weighted_player_scores_with_suits = zeros(Int, size(sorted_scores_with_suits)[1], size(sorted_scores_with_suits)[2], size(sorted_scores_with_suits)[3])
    for player in hands.players 
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
    player_score = zeros(Int, maximum(hands.players))
    for player in hands.players
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
                    end
                end
            end
        end
    end
    best_hand = maximum(player_score)
    player_winners = findall(x -> x == best_hand, player_score)
    return player_winners
end

function Four_Kind(hands::Hands)
    card_weight = [225, 15, 1]
    four_of_a_kind_checker = 0
    player_score = zeros(Int, maximum(hands.players), hands.cards)
    for player in hands.players
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
    summed_player_scores = vec(sum(sorted_player_scores[:,1:5], dims = 2))
    best_hand = maximum(summed_player_scores)
    player_winners = findall(x->x == best_hand, summed_player_scores)

    return player_winners
end

function Straight_Flush(hands::Hands)  
    add_to_each_card = [0, 1, 2, 3, 4, 5, 6]
    player_score = zeros(Int, maximum(hands.players))
    for player in hands.players
        player_hand_original = hands.hands[player, :]
        flush, suit, indices = Check_Flush_Calculator(player_hand_original) 
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
    println(@__LINE__, "  " , player_winners)
    return player_winners
end

function Check_Flush_Calculator(player_hand)
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