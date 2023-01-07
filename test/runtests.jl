using Test, Coverage, Random, StatsBase
using Probker

#~ Look at this later!
function Card_Duplication(game)
    all_cards = [game.player_cards; game.flop_cards; game.turn_card; game.river_card; game.card_pile]
    filter!(!iszero, all_cards)
    if length(all_cards) == length(unique(all_cards))
        return false 
    end
    return true
end

@testset "Test_Sample_Cards_Given_Game_Stage      " begin
    Random.seed!(43221)
    test_game_preflop = game(4, [0], [0], 0, 0, [0 0], collect(1:52),10000)
    setuped_cards = Sample_Cards_Given_Game_Stage(test_game_preflop)
    @test issubset(setuped_cards[1] , collect(1:52))
    @test issubset(setuped_cards[2] , setdiff(collect(1:52), setuped_cards[1] ))
    
    test_game_flop = game(2, [13, 14, 15, 1], [0], 0, 0, [0 0], setdiff(collect(1:52), [13, 14, 15, 1]),10000)
    setuped_cards = Sample_Cards_Given_Game_Stage(test_game_flop)
    @test setuped_cards[1] == [13, 14, 15, 1]
    @test issubset(setuped_cards[2] , setdiff(collect(1:52), setuped_cards[1]))
    
    test_game_turn = game(2, [13, 14, 15, 1], [2, 5, 52], 0, 0, [0 0], setdiff(collect(1:52), [13, 14, 15, 1], [2, 5, 52]),10000)
    setuped_cards = Sample_Cards_Given_Game_Stage(test_game_turn)
    @test setuped_cards[1] == [13, 14, 15, 1]
    @test setuped_cards[2][1:3] == [2, 5, 52]
    @test issubset(setuped_cards[2][4:5], setdiff(collect(1:52), setuped_cards[1], setuped_cards[2][1:3]  ))

    test_game_river = game(2, [13, 14, 15, 1], [2, 5, 52], 26, 0, [0 0], setdiff(collect(1:52), [13, 14, 15, 1], [2, 5, 52], 26),10000)
    setuped_cards = Sample_Cards_Given_Game_Stage(test_game_river)
    @test setuped_cards[1] == [13, 14, 15, 1]
    @test setuped_cards[2][1:4] == [2, 5, 52, 26]
    @test issubset(setuped_cards[2][5], setdiff(collect(1:52),  setuped_cards[1], setuped_cards[2][1:4]))

    test_game_after_river = game(2, [13, 14, 15, 1], [2, 5, 52], 26, 43, [0 0], setdiff(collect(1:52), [13, 14, 15, 1, 2, 5, 52, 26, 43]),10000)
    setuped_cards = Sample_Cards_Given_Game_Stage(test_game_after_river)
    @test setuped_cards[1] == [13, 14, 15, 1]
    @test setuped_cards[2] == [2, 5, 52, 26, 43]

    no_duplication_game = game(4, [0], [0], 0, 0, [0 0], collect(1:52),10000)
    flop_duplication_game = game(4, [1, 2, 3], [3], 0, 0, [0 0], [9, 10, 11],10000)
    card_pile_duplication_game = game(4, [1, 2, 3], [4], 0, 0, [0 0], [4, 10, 11],10000)
    
    @test Card_Duplication(no_duplication_game) == false
    @test Card_Duplication(flop_duplication_game) == true
    @test Card_Duplication(card_pile_duplication_game) == true

    test_game_duplication = game(2, [1, 2, 3, 4], [1, 7, 8], 0, 0, [0 0], collect(1:52), 10000)
    @test Sample_Cards_Given_Game_Stage(test_game_duplication) == "card_duplication" broken = false
    
    #! Make test for hidden cards! It is clearly needed
    for _ = 1:100
        test_game_hidden = game(2, [1, 2, 0, 0], [10, 11, 12], 26, 27, [0 0], setdiff(collect(1:52), [1, 2, 0, 0], [10, 11, 12], 26, 27), 10000)
        setuped_cards = Sample_Cards_Given_Game_Stage(test_game_hidden) 
        @test setuped_cards[1][1:2] == [1,2] 
        @test issubset(setuped_cards[1][3:4], setdiff(collect(1:52), [1, 2, 0, 0], [10, 11, 12], 26, 27) )
        @test length([setuped_cards[1]; setuped_cards[2]]) == length(unique([setuped_cards[1]; setuped_cards[2]]))
    end

    for _ = 1:100
        test_game_hidden = game(2, [1, 2, 0, 0], [10, 11, 12], 26, 0, [0 0], setdiff(collect(1:52), [1, 2, 0, 0], [10, 11, 12], 26), 10000)
        setuped_cards = Sample_Cards_Given_Game_Stage(test_game_hidden) 
        @test setuped_cards[1][1:2] == [1,2] 
        @test issubset(setuped_cards[1][3:4], setdiff(collect(1:52), [1, 2, 0, 0], [10, 11, 12], 26) )
        @test length([setuped_cards[1]; setuped_cards[2]]) == length(unique([setuped_cards[1]; setuped_cards[2]]))
    end

    for _ = 1:100
        test_game_hidden = game(2, [1, 2, 0, 0], [10, 11, 12], 0, 0, [0 0], setdiff(collect(1:52), [1, 2, 0, 0], [10, 11, 12], 26), 10000)
        setuped_cards = Sample_Cards_Given_Game_Stage(test_game_hidden) 
        @test setuped_cards[1][1:2] == [1,2] 
        @test issubset(setuped_cards[1][3:4], setdiff(collect(1:52), [1, 2, 0, 0], [10, 11, 12]) )
        @test length([setuped_cards[1]; setuped_cards[2]]) == length(unique([setuped_cards[1]; setuped_cards[2]]))
    end

    for _ = 1:100
        test_game_hidden = game(2, [1, 2, 0, 0], [0], 0, 0, [0 0], setdiff(collect(1:52), [1, 2, 0, 0], [10, 11, 12], 26), 10000)
        setuped_cards = Sample_Cards_Given_Game_Stage(test_game_hidden) 
        @test setuped_cards[1][1:2] == [1,2] 
        @test issubset(setuped_cards[1][3:4], setdiff(collect(1:52), [1, 2, 0, 0]) )
        @test length([setuped_cards[1]; setuped_cards[2]]) == length(unique([setuped_cards[1]; setuped_cards[2]]))
    end
end

@testset "Simulate_Hidden_Cards " begin
    test_game_flop = game(8, [13, 14, 15, 1, 37, 32, 21, 22, 23, 27, 28, 20, 43, 49, 0, 0], [51, 52, 26], 47, 41, [0 0], setdiff(collect(1:52), [13, 14, 15, 1, 37, 32, 21, 22, 23, 27, 28, 20, 43, 49, 0, 0], [51, 52, 26], 47, 41),10000)
    @test Card_Duplication(Simulate_Hidden_Cards(test_game_flop)) == false broken = true
end


@testset "Test_Probker.Determine_Win    " begin
    player_cards_1 = [9, 10, 13, 26]
    shared_cards_1 = [6, 7, 8, 39, 52]
    player_cards_2 = [9, 10, 13, 26]
    shared_cards_2 = [5, 7, 8, 39, 52]
    player_cards_3 = [9, 10, 21, 26]
    shared_cards_3 = [5, 7, 8, 39, 52]
    player_cards_4 = [9, 10, 6, 17]
    shared_cards_4 = [5, 7, 8, 39, 52]
    player_cards_5 = [18, 31, 6, 17]
    shared_cards_5 = [5, 7, 8, 40, 52]
    player_cards_6 = [18, 31, 12, 10]
    shared_cards_6 = [5, 32, 8, 23, 25]
    player_cards_7 = [18, 37, 12, 10]
    shared_cards_7 = [5, 32, 8, 23, 25]
    player_cards_8 = [13, 9, 26, 40]
    shared_cards_8 = [23, 8, 32, 18, 41]


    player_cards_9 = [13, 26, 8, 27]
    shared_cards_9 = [3, 7, 9, 15, 11]



    player_cards_10 = [1, 5, 18, 15]
    shared_cards_10 = [3, 7, 9, 15, 11]


    @test Probker.Determine_Win(player_cards_10, shared_cards_10) == [1]
    @test Probker.Determine_Win(player_cards_9, shared_cards_9) == [1]

    #& The flaw could be that 
    @test Probker.Determine_Win(player_cards_1, shared_cards_1) == [1]
    @test Probker.Determine_Win(player_cards_2, shared_cards_2) == [2]
    @test Probker.Determine_Win(player_cards_3, shared_cards_3) == [2]
    @test Probker.Determine_Win(player_cards_4, shared_cards_4) == [1]
    @test Probker.Determine_Win(player_cards_5, shared_cards_5) == [2]
    @test Probker.Determine_Win(player_cards_6, shared_cards_6) == [1]
    @test Probker.Determine_Win(player_cards_7, shared_cards_7) == [2]
    @test Probker.Determine_Win(player_cards_8, shared_cards_8) == [1]
    
end

@testset "Test_High_Card        " begin
    hands_1 = [13  2 4 17 19 31 34;
               12 11 4 17 19 31 34]
    hands_2 = [13  2 4 17 19 31 34;
               26 11 4 17 19 31 34]
    hands_3 = [13 24 4 17 19 31 34;
               26 11 4 17 19 31 34]
    hands_4 = [ 13  1  4 17 19 31 34;
    26  2  4 17 19 31 34;
    39  3  4 17 19 31 34;
    52 12  4 17 19 31 34;
    12  5  4 17 19 31 34;
    24  6  4 17 19 31 34;
    14  7  4 17 19 31 34;
    15  8  4 17 19 31 34;
    16  9  4 17 19 31 34]   
    @test High_Card(hands_1) == [1]
    @test High_Card(hands_2) == [2]
    @test High_Card(hands_3) == [1, 2]
    @test High_Card(hands_4) == [4] 
end

@testset "Test_Two_Of_A_Kind    " begin
    hands_1 = [13 26  1 14 18 33 42;
    5 18  1 14 18 33 42]
    hands_2 = [13  1  7 20 26 31 47;
    39 12  7 20 26 31 47]
    hands_3 = [13  1  7 20 26 31 43;
    39  2  7 20 26 31 43]
    hands_4 = [1 2 13 12 25 33 46;
    14 15 13 12 25 33 46;
    27 28 13 12 25 33 46;
    40 41 13 12 25 33 46;
    3 4 13 12 25 33 46;
    16 17 13 12 25 33 46;
    29 30 13 12 25 33 46;
    42 43 13 12 25 33 46;
    5 6 13 12 25 33 46]
    hands_5 = [ 1  2 3 4 19 20 21;
    14 15 3 4 19 20 21]
    
    @test Two_Of_A_Kind(hands_1) == [1]
    @test Two_Of_A_Kind(hands_2) == [2]
    @test Two_Of_A_Kind(hands_3) == [1, 2]
    @test Two_Of_A_Kind(hands_4) == collect(1:9)
    @test Two_Of_A_Kind(hands_5) == "non-exsistent"
end

@testset "Test_Two_Pairs        " begin
    hands_1 = [13 26  1 14 18 33 42;
    5 18  1 14 18 33 42]
    hands_2 = [13  1  7 20 26 31 47;
    39 12  7 20 26 31 47]
    hands_3 = [13  1  7 20 26 31 43;
    39  2  7 20 26 31 43]
    hands_4 = [1 2 13 12 25 33 46;
    14 15 13 12 25 33 46;
    27 28 13 12 25 33 46;
    40 41 13 12 25 33 46;
    3 4 13 12 25 33 46;
    16 17 13 12 25 33 46;
    29 30 13 12 25 33 46;
    42 43 13 12 25 33 46;
    5 6 13 12 25 33 46]
    hands_5 = [1 2 3 4 19 20 21;
    14 15 3 4 19 20 21 ]
    
    @test Two_Pairs(hands_1) == [1]
    @test Two_Pairs(hands_2) == [2]
    @test Two_Pairs(hands_3) == [1, 2]
    @test Two_Pairs(hands_4) == collect(1:9)
    @test Two_Pairs(hands_5) == "non-exsistent"
end

@testset "Test_Three_Of_A_Kind  " begin
    hands_1 = [13 26 39 1 15 17 38;
    12 25 39 1 15 17 38]
    hands_2 = [13  1 14 26 39 3 7;
    52 27 14 26 39 3 7]
    hands_3 = [13  1 14 26 39 3 7;
    52 12 14 26 39 3 7]
    hands_4 = [1 2 3 17 18 19 38;
    14 15 3 17 18 19 38]
    hands_5 = [1 2 3 17 18 19 38;
    14 15 3 17 18 19 38
    4 6 3 17 18 19 38;
    9 10 3 17 18 19 38
    27 28 3 17 18 19 38;
    50 30 3 17 18 19 38
    34 38 3 17 18 19 38;
    42 43 3 17 18 19 38
    16 29 3 17 18 19 38]
    
    @test Three_Of_A_Kind(hands_1) == [1]
    @test Three_Of_A_Kind(hands_2) == [1, 2]
    @test Three_Of_A_Kind(hands_3) == [2]
    @test Three_Of_A_Kind(hands_4) == "non-exsistent"
    @test Three_Of_A_Kind(hands_5) == [9]
end

@testset "Test_Straight         " begin
    hands_1 = [1 2 3 4 18 50 51;
    14 15 3 4 18 50 51]
    hands_2 = [17 18 19 20 34 1 2;
    35 49 19 20 34 1 2]
    hands_3 = [1 2 3 18 19 20 21;
    14 15 3 18 19 20 21]
    
    @test Straight(hands_1) == [1,2]
    @test Straight(hands_2) == [2]
    @test Straight(hands_3) == "non-exsistent"
    
end

@testset "Test_Flush            " begin
    hands_1 = [1 2 3 4 5 50 52;
    6 7 3 4 5 50 52]
    hands_2 = [1 2 52 51 50 49 48;
    12 13 52 51 50 49 48]
    hands_3 = [1 2 3 14 15 16 43;
    5 6 3 14 15 16 43]
    @test Flush(hands_1) == [2]
    @test Flush(hands_2) == [1, 2]
    @test Flush(hands_3) == "non-exsistent"
    
end


@testset "Test_Full_House       " begin
    
    hands_1 = [14  2 12 25  3 16 29;
    4 38 12 25  3 16 29]
    hands_2 = [1  2 12 25  3 16 29;
    17 13 12 25  3 16 29]
    hands_3 = [1 15  3 18 19  7 22;                   
    14 28 3 18 19 7 22]
    @test Full_House(hands_1) == [2]
    @test Full_House(hands_2) == [1, 2]
    @test Full_House(hands_3) == "non-exsistent"
end

@testset "Test_Four_Of_A_Kind   " begin
    
    hands_1 = [1 14 27 40 26 3 5;
    2 15 27 40 26 3 5]
    hands_2 = [12 11 5 18 31 44 3;
    13 1 5 18 31 44 3]    
    hands_3 = [1 2 3 16 29 42 12;
    10 11 3 16 29 42 12]
    hands_4 = [1 14 2 16 42 9 19;
    3 15 2 16 42 9 19]
    @test Four_Of_A_Kind(hands_1) == [1]
    @test Four_Of_A_Kind(hands_2) == [2]
    @test Four_Of_A_Kind(hands_3) == [1, 2]
    @test Four_Of_A_Kind(hands_4) == "non-exsistent"
end

@testset "Test_Straight_Flush   " begin
    hands_1 = [ 1  2  3  4  5  6  7;
    5 15 18 29 42 51 31]
    hands_2 = [ 1 2 3 4 5 6 7;
    52 8 3 4 5 6 7]
    hands_3 = [1  2  26 25 24 23 22;
    13 21 26 25 24 23 22]
    hands_4 = [1  14 27 40  2  3  4;
    13 26 27 40  2  3  4]
    @test Straight_Flush(hands_1) == [1]
    @test Straight_Flush(hands_2) == [2]
    @test Straight_Flush(hands_3) == [1, 2]
    @test Straight_Flush(hands_4) == "non-exsistent"
end;
