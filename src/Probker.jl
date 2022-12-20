module Probker

using StatsBase, Random

#& Refactoring this will be so satisfying

struct game 
    number_of_players::Int64
    player_cards::Vector{Int64}
    flop_cards::Vector{Int64}
    turn_card::Int64
    river_card::Int64 
    fold_pattern::Matrix{Int64}
    card_pile::Vector{Int64}
    number_of_simulations::Int64
end

# const specific_game = game(2, [1,2,3,4], [5,6,7], 0, 0, [0 0], collect(8:52), 1000)

export Probker_Main
export Simulate
export Determine_Win
export Sample_Cards_Given_Game_Stage, Sample_From_Flop, Sample_From_Preflop, Sample_From_Turn, Sample_From_River, Sample_From_Start
export High_Card, Two_Of_A_Kind, Two_Pairs, Three_Of_A_Kind, Straight, Flush, Full_House, Four_Of_A_Kind, Straight_Flush
export Card_Duplication
export game
export calling_probker

function Probker_Main(game)
    return Simulate(game)
end

function Simulate(game)
    wins_by_player = zeros(Int64, game.number_of_players )
    split_by_player = zeros(Float64, game.number_of_players)
    for _ = 1:game.number_of_simulations
        player_cards, shared_cards = Sample_Cards_Given_Game_Stage(game)
        player_winners = Determine_Win(player_cards, shared_cards)
        if length(player_winners) == 1
            wins_by_player[player_winners] .+= 1
        else
            number_of_players_in_split = 1/length(player_winners)
            split_by_player[player_winners] .+= number_of_players_in_split
        end
    end
    return wins_by_player/game.number_of_simulations#, split_by_player/game.number_of_simulations
end

function Sample_Cards_Given_Game_Stage(game)
    try
        if Card_Present(game.river_card)
            return Sample_From_River(game)
        elseif Card_Present(game.turn_card)
            return Sample_From_Turn(game)
        elseif Card_Present(game.flop_cards)
            return Sample_From_Flop(game)
        elseif Card_Present(game.player_cards) 
            return Sample_From_Preflop(game)
        else
            return Sample_From_Start(game)
        end
    finally
        if Card_Duplication(game)
            println("card duplication")
            return "card_duplication"
        end
    end
end

function Simulate_Hidden_Cards(game, card_pile)
    player_cards = deepcopy(game.player_cards)
    index_of_hidden_cards = findall(x->x == 0, player_cards)
    hidden_cards = sample(card_pile, length(index_of_hidden_cards), replace = false)
    player_cards[index_of_hidden_cards] .= hidden_cards
    setdiff!(card_pile, hidden_cards)
    return player_cards, card_pile
end

function Sample_From_River(game)
    card_pile = deepcopy(game.card_pile)
    player_cards, card_pile = Simulate_Hidden_Cards(game, card_pile)
    shared_cards = [game.flop_cards ; game.turn_card ; game.river_card]
    return player_cards, shared_cards
end

function Sample_From_Turn(game)
    card_pile = deepcopy(game.card_pile)
    player_cards, card_pile = Simulate_Hidden_Cards(game, card_pile)
    river_card, card_pile = Sample_And_Update_Card_Pile(1, card_pile)
    shared_cards = [game.flop_cards ; game.turn_card ; river_card]
    return player_cards, shared_cards
end

function Sample_From_Flop(game)
    card_pile = deepcopy(game.card_pile)
    player_cards, card_pile = Simulate_Hidden_Cards(game, card_pile)
    turn_and_river_cards,  card_pile = Sample_And_Update_Card_Pile(2, card_pile)
    shared_cards = [game.flop_cards ; turn_and_river_cards]
    return player_cards, shared_cards
end

function Sample_From_Preflop(game)
    card_pile = deepcopy(game.card_pile)
    player_cards, card_pile = Simulate_Hidden_Cards(game,card_pile)
    shared_cards, card_pile = Sample_And_Update_Card_Pile(5, card_pile)
    return player_cards, shared_cards
end

function Sample_From_Start(game)
    card_pile = deepcopy(game.card_pile)
    all_cards, card_pile = Sample_And_Update_Card_Pile(5 + 2*game.number_of_players, card_pile)
    return all_cards[1:2*game.number_of_players], all_cards[2*game.number_of_players+1:end]
end

function Sample_And_Update_Card_Pile(number_of_samples, card_pile)
    cards = sample(card_pile, number_of_samples, replace = false)
    setdiff!(card_pile, cards)
    return cards, card_pile
end

function Card_Duplication(game)
    all_cards = [game.player_cards; game.flop_cards; game.turn_card; game.river_card; game.card_pile]
    filter!(!iszero, all_cards)
    if length(all_cards) == length(unique(all_cards))
        return false 
    end
    return true
end

function Card_Present(card)
    if typeof(card) == Vector{Int64}
        return card != [0]
    else
        return card != 0
    end
end

function Determine_Win(player_cards, shared_cards)
    hands_for_each_player = Cards_To_Hands(player_cards, shared_cards)
    determine_hand = (Straight_Flush, Four_Of_A_Kind, Full_House, Flush, Straight, Three_Of_A_Kind, Two_Pairs, Two_Of_A_Kind, High_Card)
    for fun in determine_hand
        if fun(hands_for_each_player) == "non-exsistent"
            continue
        else
            return fun(hands_for_each_player)
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
    return hands_for_each_player
end


function High_Card(hands_for_each_player)
    modulus_13_hands = hands_for_each_player .% 13
    modulus_13_hands[modulus_13_hands .== 0] .= 13
    sorted_hands = sort(modulus_13_hands, dims = 2, rev = true)
    winners = zeros(Int64,length(hands_for_each_player[:,1]),5)
    for card = 1:5
        highest_card = 0
        for player = 1:length(hands_for_each_player[:,1])
            if sorted_hands[player, card] == highest_card
                winners[player,card] = 1
                highest_card = sorted_hands[player, card]
            elseif sorted_hands[player, card] > highest_card
                winners[:     ,card] .= 0
                winners[player,card] = 1
                highest_card = sorted_hands[player, card]
            end
        end
    end
    card_weight = [16 ,8, 4, 2, 1]
    player_scores = winners * card_weight 
    best_hand = findmax(player_scores)[1]
    winner_players = findall(x->x == best_hand, player_scores)
    return winner_players
end

function Two_Of_A_Kind(hands_for_each_player)
    if Check_For_Two_Kind(hands_for_each_player)
        return "non-exsistent"
    end
    modulus_13_hands = hands_for_each_player .% 13
    modulus_13_hands[modulus_13_hands .== 0] .= 13
    sorted_hands = sort(modulus_13_hands, dims = 2, rev = true)
    player_scores = zeros(Int64, length(hands_for_each_player[:,1]), 7)
    card_weight = [64, 32, 16, 8, 4, 2, 1]
    for player = 1:length(hands_for_each_player[:, 1])
        for card = 1:7
            if card != 1 && sorted_hands[player, card] == sorted_hands[player, card - 1]
                continue
            end
            if card != 7 && sorted_hands[player, card] == sorted_hands[player, card + 1] 
                player_scores[player, card] = 3000*sorted_hands[player, card]
                player_scores[player, card + 1] = 3000*sorted_hands[player, card]
                two_of_a_kind_checker = 1
            else 
                player_scores[player, card] = card_weight[card] * sorted_hands[player, card]
            end
        end
    end
    sorted_score = sort(player_scores, dims = 2, rev = true)
    summed_score = sum(sorted_score[:, 1:5], dims = 2)
    vector_summed_score = []
    for player = 1:length(hands_for_each_player[:,1])
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

function Two_Pairs(hands_for_each_player)
    if Check_For_Two_Pairs(hands_for_each_player)
        return "non-exsistent"
    end
    modulus_13_hands = hands_for_each_player .% 13
    modulus_13_hands[modulus_13_hands .== 0] .= 13
    sorted_hands = sort(modulus_13_hands, dims = 2, rev = true)
    players = 1:length(hands_for_each_player[:,1])
    cards = 1:length(hands_for_each_player[1,:])
    player_scores = zeros(Int64, length(hands_for_each_player[:,1]), 7)
    card_weight = [64, 32, 16, 8, 4, 2, 1]
    two_pairs_checker = zeros(Int64, length(hands_for_each_player[:,1]))
    for player in players
        first_pair = 1
        for card in cards
            if card != 1 && sorted_hands[player, card] == sorted_hands[player, card - 1]
                if card == 7 && player_scores[player, card] == 0  
                    player_scores[player, card] = sorted_hands[player, card]
                end
                continue
            end
            if card != 7 && sorted_hands[player, card] == sorted_hands[player, card + 1] && two_pairs_checker[player] < 2
                pair_weight = 3000
                if first_pair == 1
                    pair_weight = 15*3000
                    first_pair = 0
                end
                player_scores[player, card] = pair_weight*sorted_hands[player, card]
                player_scores[player, card + 1] = pair_weight*sorted_hands[player, card ]
                two_pairs_checker[player] += 1            
            else
                player_scores[player, card] = card_weight[card] * sorted_hands[player, card]
            end
        end    
    end

    sorted_scores = sort(player_scores, dims = 2, rev = true)
    for player in players
        pair_count = 0
        first_card_of_pair = 0
        for card in setdiff!(collect(cards), 7)
            if sorted_scores[player, card] == sorted_scores[player, card + 1]
                pair_count += 1
                first_card_of_pair = card
            end
        end
        if pair_count == 1
            sorted_scores[player,first_card_of_pair] = sorted_scores[player,first_card_of_pair]/15
            sorted_scores[player,first_card_of_pair + 1] = sorted_scores[player,first_card_of_pair + 1]/15
        end
    end
    summed_scores = sum(sorted_scores[:,1:5], dims = 2)
    vector_summed_scores = []
    for player in players
        push!(vector_summed_scores, summed_scores[player])
    end
    best_hand = findmax(vector_summed_scores)[1]
    player_winners = findall(x->x == best_hand, vector_summed_scores)
    return player_winners
end

function Check_For_Two_Pairs(hands_for_each_player)
    mod_hands = hands_for_each_player .% 13
    for i = 1:length(hands_for_each_player[:,1])
        if 7 == 2 + length(unique(mod_hands[i,:]))
            return false
        end
    end
    return true
end

function Three_Of_A_Kind(hands_for_each_player)
    # if Checker_Three_Of_A_Kind
    #     return "non-exsistent"
    # end

    modulus_13_hands = hands_for_each_player .% 13
    modulus_13_hands[modulus_13_hands .== 0 ] .= 13
    sorted_hands = sort(modulus_13_hands, dims = 2, rev = true)
    players = 1:length(hands_for_each_player[:,1])
    cards = 1:length(hands_for_each_player[1,:])
    player_scores = zeros(Int64, length(players), length(cards))
    card_weight = [64, 32, 16, 8, 4, 2, 1]
    exsistent_three_kind = 0
    for player in players
        three_kind = 0
        card = 1
        while card <= 7 
            if three_kind == 0 && card <= 5 && sorted_hands[player, card] == sorted_hands[player, card + 1] == sorted_hands[player, card + 2] 
                player_scores[player, card + 0] = 3000*sorted_hands[player, card + 0]
                player_scores[player, card + 1] = 3000*sorted_hands[player, card + 1]
                player_scores[player, card + 2] = 3000*sorted_hands[player, card + 2]
                three_kind = 1
                exsistent_three_kind = 1
                card += 2
            else
                player_scores[player, card] = card_weight[card]*sorted_hands[player, card]
            end
            card += 1
        end
    end
    if exsistent_three_kind == 0
        return "non-exsistent"
    end
    sorted_scores = sort(player_scores, dims = 2, rev = true)
    summed_scores = sum(sorted_scores[:,1:5], dims = 2)
    vector_summed_scores = []
    for player in players
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

function Straight(hands_of_each_player)
    players = 1:length(hands_of_each_player[:,1])
    cards = 1:length(hands_of_each_player[1,:])
    modulus_13_hands = hands_of_each_player .% 13
    modulus_13_hands[modulus_13_hands .== 0] .= 13
    sorted_hands = sort(modulus_13_hands, dims = 2)
    straight_check = 0
    player_scores = zeros(Int64, length(players))
    for player in players
        count = 1
        ace_updated_hand = sorted_hands[player,:]
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
        return "non-exsistent"
    end
    best_hand = findmax(player_scores)[1]
    player_winners = findall(x->x == best_hand, player_scores)
    return player_winners
end

function Flush(hands_of_each_player)
    players = 1:length(hands_of_each_player[:,1])
    cards = 1:length(hands_of_each_player[1,:])
    modulus_13_hands = hands_of_each_player .% 13
    modulus_13_hands[modulus_13_hands .== 0] .= 13
    sorted_hands = sort(modulus_13_hands, dims = 2, rev = true)
    flush_checker = 0
    card_weight = [64, 32, 16, 8, 4, 2, 1]
    player_scores_with_suits = zeros(Int64, length(players), length(cards), 4)
    for player in players
        count_suit = zeros(Int64, 4)
        for card in cards
            if hands_of_each_player[player, card] <= 13
                player_scores_with_suits[player, card, 1] = Card_To_Kind(hands_of_each_player[player, card])
            elseif hands_of_each_player[player, card] <= 26
                player_scores_with_suits[player, card, 2] = Card_To_Kind(hands_of_each_player[player, card])
            elseif hands_of_each_player[player, card] <= 39
                player_scores_with_suits[player, card, 3] = Card_To_Kind(hands_of_each_player[player, card])
            elseif hands_of_each_player[player, card] <= 52
                player_scores_with_suits[player, card, 4] = Card_To_Kind(hands_of_each_player[player, card])
            end
        end
    end
    for player in players
        for suit = 1:4
            if sum(player_scores_with_suits[player, :, suit] .> 0.5 ) >= 5
                player_scores_with_suits[player, :, suit] = 20*player_scores_with_suits[player, :, suit]
                player_scores_with_suits[player, :, setdiff(1:4, suit)] .= 0 
                flush_checker = 1
            end
        end
    end
    if flush_checker == 0
        return "non-exsistent"
    end
    sorted_scores_with_suits = sort(player_scores_with_suits, dims = 2, rev = true)
    card_weight = [64, 32, 16, 8, 4, 2, 1]
    weighted_player_scores_with_suits = zeros(Int64, size(sorted_scores_with_suits)[1], size(sorted_scores_with_suits)[2], size(sorted_scores_with_suits)[3])
    for player in players 
        for card in cards
            for suit = 1:4
                weighted_player_scores_with_suits[player, card, suit] = card_weight[card]*sorted_scores_with_suits[player, card, suit]
            end
        end
    end
    player_scores = sum(weighted_player_scores_with_suits[:, card, suit] for card = 1:5 for suit = 1:4)
    best_hand = findmax(player_scores)[1]
    player_winners = findall(x->x == best_hand, player_scores)
    return player_winners 
end

function Full_House(hands_of_each_player)
    players = 1:length(hands_of_each_player[:, 1])
    cards = 1:length(hands_of_each_player[1, :])
    modulus_hands = hands_of_each_player .% 13
    modulus_hands[modulus_hands .== 0] .= 13
    sorted_hands = sort(modulus_hands, dims = 2, rev = true)
    player_score = zeros(Int64, length(players))
    full_house_checker = 0
    for player in players
        hand_for_a_given_player = sorted_hands[player, :]
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
        return "non-exsistent"
    end
    best_hand = findmax(player_score)[1]
    player_winners = findall(x->x == best_hand, player_score)
    winners = []
    for i = 1:length(player_winners)
        push!(winners, player_winners[i][1])    
    end
    return  winners
end

function Four_Of_A_Kind(hands_of_each_player)
    players = 1:length(hands_of_each_player[:, 1])
    cards = 1:length(hands_of_each_player[1, :])    
    modulus_hands = hands_of_each_player .% 13
    modulus_hands[modulus_hands .== 0] .= 13
    sorted_hands = sort(modulus_hands, dims = 2, rev = true)
    card_weight = [225, 15, 1]
    four_of_a_kind_checker = 0
    player_score = zeros(Int64, length(players), length(cards))
    for player in players
        for i = 1:13
            find_n_kinds = findall(x->x ==i, sorted_hands[player, :])
            if length(find_n_kinds) ==  4
                player_score[player, find_n_kinds] = 10000*sorted_hands[player, find_n_kinds]
                remaining_cards = setdiff(1:7, find_n_kinds )
                player_score[player, remaining_cards] = card_weight .* sorted_hands[player, remaining_cards]
                four_of_a_kind_checker = 1
            end
        end
    end
    if four_of_a_kind_checker == 0
        return "non-exsistent"
    end
    sorted_player_scores = sort(player_score, dims = 2, rev = true)
    summed_player_scores = sum(sorted_player_scores[:,1:5], dims = 2)
    best_hand = findmax(summed_player_scores)[1]
    player_winners = findall(x->x == best_hand, summed_player_scores)
    winners = []
    for i = 1:length(player_winners)
        push!(winners, player_winners[i][1])    
    end
    return winners
end

function Straight_Flush(hands_for_each_player)
    players = 1:length(hands_for_each_player[:, 1])
    cards = 1:length(hands_for_each_player[1, :])
    straight_flush_checker = 0
    modulus_hands = hands_for_each_player .% 13
    modulus_hands[modulus_hands .== 0] .= 13
    sorted_hands = sort(modulus_hands, dims = 2, rev = true)
    
    add_to_each_card = [0, 1, 2, 3, 4, 5, 6]
    player_score = zeros(Int64, length(players))
    for player in players
        player_hand_original = hands_for_each_player[player, :]
        flush, suit, indices = Check_For_Flush(player_hand_original) 
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
        return "non-exsistent"
    end
    
    best_hand = findmax(player_score)[1]
    player_winners = findall(x->x == best_hand, player_score)
    
    return player_winners
end

function Check_For_Flush(player_hand)
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

