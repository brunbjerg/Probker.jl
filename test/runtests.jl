using Test
using Random
using StatsBase
using Probker
using Profile
using PProf
using BenchmarkTools
using Revise
revise(Probker)

#& The structure of the test file is degrading fast. 
#& We have wrapped this around too many times. Hmm... the problem is 
#& that I would to change to a Vector based formulation. Should I do this
#& now? We also have the problem. 

#TODO###################################################
#TODO######               TODO               ###########
#TODO###################################################

#// TODO Test straight flush throughly
#// TODO Test straight throughly
#// TODO Make probability fold
#TODO change the whole implementation to single array based


Profile.clear(); @profile Simulate(Game(2, [0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0], 100000)); pprof()

#& Card_Duplication errors should be handled in the hands constructor. 
#& I should plan my day now. Make some wraps.
@testset "Simulate_Hidden_Cards " begin
    test_game_flop = Game(8, [13, 14, 15, 1, 37, 32, 21, 22, 23, 27, 28, 20, 43, 49, 0, 0, 51, 52, 26, 47, 41], [0, 0, 0, 0], 10000)
    @test Card_Duplication(Sample(test_game_flop)) == false broken = true
end

@testset "Check that folded hands never win" begin
    test_game_fold =  Game(2, [0, 0, 13, 0, 0, 0, 0, 0, 0], [0, 0, -1, -1], 100000)
    @test Simulate(test_game_fold)[1][2] == 0.0
    test_game_fold =  Game(2, [0, 13, 0, 0, 0, 0, 0, 0, 0], [0, 0, -1, -1], 100000)
    @test Simulate(test_game_fold)[1][2] == 0.0
    test_game_fold =  Game(2, [26, 13, 0, 0, 0, 0, 0, 0, 0], [-1, -1, 0, 0], 100000)
    @test Simulate(test_game_fold)[1][2] == 1.0
    test_game_fold =  Game(2, [0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0], 100000)
    @test Simulate(test_game_fold)[1][2] == 1.0 broken = true

    test_game_fold =  Game(2, [0, 0, 0, 0, 0, 0, 0, 0, 0], [-1, -1, -1, -1], 100000)
    @test Simulate(test_game_fold)[1][2] == 0.0

end

#& I should make a test function that allow just to test with samples.
#& How would that work? It should be able to extract the hands from
#& the conditional simulation. 

#& The straight function must be wrong. My tests have degenerated. 

#& That is not good. I find myself afraid of trusting them. This is a 
#& huge problem and a pattern that I should get out of instantly. 

@testset "cannot win with hand worse than what you got" begin
    

    winners, spilt, hands = Simulate(Game(2, [25, 37, 0, 0, 49, 9, 8, 0, 0], [0, 0, 0, 0], 100000))
    
    
    println(@__LINE__, " hands " , hands)
    @test issubset(hands[1], [0, 1, 2, 3, 4, 5])


end


#& Hmm... There is a different problem here! How can the first player win when he was folded?


@testset "Test Checker_Hands" begin
    # royal flush vs four kind
    player_cards_1 = [1, 3, 13, 26]
    shared_cards_1 = [9, 11, 8, 12, 10]
    @test Check_Straight_Flush(Cards_To_Hands(player_cards_1, shared_cards_1, [0, 0, 0, 0])) 

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

    player_cards_11 = [23, 13, 5, 51]
    shared_cards_11 = [3, 9, 10, 42, 38]

    player_cards_12 = [48, 51, 1, 11+13+13]
    shared_cards_12 = [1 + 13 + 13,3 + 13,13,4,13 + 13 + 13 + 5]

    hands_1 = Hands([   47 11 21 40 39 14 34;
                        26  7 21 40 39 14 34;
                        17 38 21 40 39 14 34;], [0, 0, 0, 0, 0, 0])

    @test Hands_Checker(Cards_To_Hands(player_cards_1, shared_cards_1, [0, 0, 0, 0]))[1]   == [2]
    @test Hands_Checker(Cards_To_Hands(player_cards_2, shared_cards_2, [0, 0, 0, 0]))[1]   == [2]
    @test Hands_Checker(Cards_To_Hands(player_cards_3, shared_cards_3, [0, 0, 0, 0]))[1]   == [2]
    @test Hands_Checker(Cards_To_Hands(player_cards_4, shared_cards_4, [0, 0, 0, 0]))[1]   == [1]
    @test Hands_Checker(Cards_To_Hands(player_cards_5, shared_cards_5, [0, 0, 0, 0]))[1]   == [2]
    @test Hands_Checker(Cards_To_Hands(player_cards_6, shared_cards_6, [0, 0, 0, 0]))[1] == [1]
    @test Hands_Checker(Cards_To_Hands(player_cards_7, shared_cards_7, [0, 0, 0, 0]))[1] == [2]
    @test Hands_Checker(Cards_To_Hands(player_cards_8, shared_cards_8, [0, 0, 0, 0]))[1] == [1]
    @test Hands_Checker(Cards_To_Hands(player_cards_9, shared_cards_9, [0, 0, 0, 0]))[1]   == [1]
    @test Hands_Checker(Cards_To_Hands(player_cards_10, shared_cards_10, [0, 0, 0, 0]))[1] == [1]
    @test Hands_Checker(Cards_To_Hands(player_cards_11, shared_cards_11, [0, 0, 0, 0]))[1] == [2]
    @test Hands_Checker(Cards_To_Hands(player_cards_12, shared_cards_12, [0, 0, 0, 0]))[1] == [2]
    @test Hands_Checker(hands_1)[1] == [1]

    @test Hands_Checker(Cards_To_Hands([1, 2, 15, 19], [3, 4, 5, 32, 50], [0, 0, 0, 0]))[1] == [1]


end

@testset "Test checker functions" begin

    #& It is the checker function that is wrong. 
    hands_1 = Hands([    1 2 3 4 5 8 9;
                        11 12 3 4 5 8 9], [0, 0, 0, 0])
    hands_2 = Hands([1 3 5 7 9 11 13;
                     2 4 5 7 9 11 13], [0, 0, 0, 0])
    @test Check_Straight(hands_1::Hands) == true
    @test Check_Straight(hands_2::Hands) == false

    #& Right now I am getting that the 


    player_cards_4 = [9, 10, 6, 17]
    shared_cards_4 = [5, 7, 8, 39, 52]

    @test Check_Straight(Cards_To_Hands(player_cards_4, shared_cards_4, [0, 0, 0, 0])) 

    player_cards_12 = [48, 51, 1, 11+13+13]
    shared_cards_12 = [1+13+13,3+13,13,4,13+13+13+5]

    #& I should make the hands constructor take two different input types.
    #& I should make a function for creating hands and change the hands field in the 
    #& struct to be a single array. 
    hands_3 = Hands([   1 14 27 13 26 2 3;
                        4 5 27 13 26 2 3], [0, 0, 0, 0])
    hands_4 = Hands([   1 2 3 4 5 6 7;
                        8 9 3 4 5 6 7], [0, 0, 0, 0])


    hands_12 = Cards_To_Hands(player_cards_12, shared_cards_12, [0, 0, 0, 0])

    @test Check_Full_House(hands_3) == true
    @test Check_Full_House(hands_4) == false
    @test Check_Straight(hands_12) == false

    hands_5 = Hands([1 14 27 2 3 4 5; 13 15 27 2 3 4 5], [0, 0, 0, 0])
    hands_6 = Hands([1  8 27 2 3 4 5; 13 15 27 2 3 4 5], [0, 0, 0, 0])
    @test Check_Three_Kind(hands_5) == true
    @test Check_Three_Kind(hands_6) == false
end


@testset "Test_High_Card" begin
    hands_1 = Hands([   13  2 4 17 19 31 34;
                        12 11 4 17 19 31 34], [0, 0, 0, 0])

    hands_2 = Hands([   13  2 4 17 19 31 34;
                        26 11 4 17 19 31 34], [0, 0, 0, 0])

    hands_3 = Hands([   13 24 4 17 19 31 34;
                        26 11 4 17 19 31 34], [0, 0, 0, 0])

    hands_4 = Hands([   13  1  4 17 19 31 34;
                        26  2  4 17 19 31 34;
                        39  3  4 17 19 31 34;
                        52 12  4 17 19 31 34;
                        12  5  4 17 19 31 34;
                        24  6  4 17 19 31 34;
                        14  7  4 17 19 31 34;
                        15  8  4 17 19 31 34;
                        16  9  4 17 19 31 34], [0, 0, 
                        0, 0,
                        0, 0, 
                        0, 0, 
                        0, 0,
                        0, 0, 
                        0, 0, 
                        0, 0,
                        0, 0,])
                        
    @test High_Card(hands_1) == [1]
    @test High_Card(hands_2) == [2]
    @test High_Card(hands_3) == [1, 2]
    @test High_Card(hands_4) == [4] 
end

@testset "Test_Two_Kind" begin
    hands_1 = Hands([   13 26  1 14 18 33 42;
                        5 18  1 14 18 33 42], [0, 0, 0, 0])
    hands_2 = Hands([   13  1  7 20 26 31 47;
                        39 12  7 20 26 31 47], [0, 0, 0, 0])
    hands_3 = Hands([   13  1  7 20 26 31 43;
                        39  2  7 20 26 31 43], [0, 0, 0, 0])
    hands_4 = Hands([   1 2 13 12 25 33 46;
                        14 15 13 12 25 33 46;
                        27 28 13 12 25 33 46;
                        40 41 13 12 25 33 46;
                        3 4 13 12 25 33 46;
                        16 17 13 12 25 33 46;
                        29 30 13 12 25 33 46;
                        42 43 13 12 25 33 46;
                        5 6 13 12 25 33 46], [0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0 ,0 ,0, 0, 0, 0, 0 ,0 ,0])
    hands_5 = Hands([   1  2 3 4 19 20 21;
                        14 15 3 4 19 20 21], [0, 0, 0, 0])
    
    @test Two_Kind(hands_1) == [1]
    @test Two_Kind(hands_2) == [2]
    @test Two_Kind(hands_3) == [1, 2]
    @test Two_Kind(hands_4) == collect(1:9)
end

@testset "Test_Two_Pairs" begin
    hands_1 = Hands([   13 26  1 14 18 33 42;
                        5 18  1 14 18 33 42], [0, 0, 0, 0])
    hands_2 = Hands([   13  1  7 20 26 31 47;
                        39 12  7 20 26 31 47], [0, 0, 0, 0])
    hands_3 = Hands([   13  1  7 20 26 31 43;
                        39  2  7 20 26 31 43], [0, 0, 0, 0])
    hands_4 = Hands([   1 2 13 12 25 33 46;
                        14 15 13 12 25 33 46;
                        27 28 13 12 25 33 46;
                        40 41 13 12 25 33 46;
                        3 4 13 12 25 33 46;
                        16 17 13 12 25 33 46;
                        29 30 13 12 25 33 46;
                        42 43 13 12 25 33 46;
                        5 6 13 12 25 33 46], [0, 0, 0, 0, 0, 0, 0 ,0 ,0 ,0 ,0 ,0 , 0, 0, 0,0 ,0 ,0])
    hands_5 = Hands([   1 2 3 4 19 20 21;
                        14 15 3 4 19 20 21 ], [0, 0, 0, 0])


    @test Two_Pairs(hands_1) == [1]
    @test Two_Pairs(hands_2) == [2]
    @test Two_Pairs(hands_3) == [1, 2]
    @test Two_Pairs(hands_4) == collect(1:9)
end

@testset "Test_Three_Kind" begin
    hands_1 = Hands([   13 26 39 1 15 17 38;
                        12 25 39 1 15 17 38], [0, 0, 0, 0])
    hands_2 = Hands([   13  1 14 26 39 3 7;
                        52 27 14 26 39 3 7], [0, 0, 0, 0])
    hands_3 = Hands([   13  1 14 26 39 3 7;
                        52 12 14 26 39 3 7], [0, 0, 0, 0])
    hands_4 = Hands([   1 2 3 17 18 19 38;
                        14 15 3 17 18 19 38], [0, 0, 0, 0])
    hands_5 = Hands([   1 2 3 17 18 19 38;
                        14 15 3 17 18 19 38
                        4 6 3 17 18 19 38;
                        9 10 3 17 18 19 38
                        27 28 3 17 18 19 38;
                        50 30 3 17 18 19 38
                        34 38 3 17 18 19 38;
                        42 43 3 17 18 19 38
                        16 29 3 17 18 19 38], [ 0, 0, 
                                                0, 0, 0, 0, 
                                                0, 0, 0, 0, 
                                                0, 0, 0, 0, 
                                                0, 0, 0, 0])
    
    @test Three_Kind(hands_1) == [1]
    @test Three_Kind(hands_2) == [1, 2]
    @test Three_Kind(hands_3) == [2]
    @test Three_Kind(hands_5) == [9]
end

@testset "Test_Straight" begin
    hands_1 = Hands([    1  2  3  4 18 50 51;
                        14 15  3  4 18 50 51], [0, 0, 0, 0])
    hands_2 = Hands([   17 18 19 20 34  1  2;
                        35 49 19 20 34  1  2], [0, 0, 0, 0])
    hands_3 = Hands([    1  2  3 18 19 20 21;
                        14 15  3 18 19 20 21], [0, 0, 0, 0])
    hands_4 = Hands([   13 11  8 22 17 27 42;
                        28 39  8 22 17 27 42], [0, 0, 0, 0])

    @test Straight(hands_1) == [1, 2]
    @test Straight(hands_2) == [2]
    @test Straight(hands_4) == [2]
end

@testset "Test_Flush" begin
    hands_1 = Hands([   1 2 3 4 5 50 52;
                        6 7 3 4 5 50 52], [0, 0, 0, 0])
    hands_2 = Hands([   1 2 52 51 50 49 48;
                        12 13 52 51 50 49 48], [0, 0, 0, 0])
    hands_3 = Hands([   1 2 3 14 15 16 43;
                        5 6 3 14 15 16 43], [0, 0, 0, 0])
    @test Flush(hands_1) == [2]
    @test Flush(hands_2) == [1, 2]
    
end


@testset "Test_Full_House" begin

    hands_1 = Hands([   14  2 12 25  3 16 29;
                        4 38 12 25  3 16 29], [0, 0, 0, 0])
    hands_2 = Hands([   1  2 12 25  3 16 29;
                        17 13 12 25  3 16 29], [0, 0, 0, 0])
    hands_3 = Hands([   1 15  3 18 19  7 22;                   
                        14 28 3 18 19 7 22], [0, 0, 0, 0])
    hands_4 = Hands([   47 11 21 40 39 14 34;
                        26  7 21 40 39 14 34;
                        17 38 21 40 39 14 34;], [0, 0, 0, 0, 0, 0])
    
    
    
    @test Full_House(hands_1) == [2]
    @test Full_House(hands_2) == [1, 2]
    @test Full_House(hands_4) == [1]
    
end

@testset "Test_Four_Kind" begin
    
    hands_1 = Hands([   1 14 27 40 26 3 5;
                        2 15 27 40 26 3 5], [0, 0, 0, 0])
    hands_2 = Hands([   12 11 5 18 31 44 3;
                        13 1 5 18 31 44 3], [0, 0, 0, 0])    
    hands_3 = Hands([   1 2 3 16 29 42 12;
                        10 11 3 16 29 42 12], [0, 0, 0, 0])
    hands_4 = Hands([   1 14 2 16 42 9 19;
                        3 15 2 16 42 9 19], [0, 0, 0, 0])
    @test Four_Kind(hands_1) == [1]
    @test Four_Kind(hands_2) == [2]
    @test Four_Kind(hands_3) == [1, 2]
end

@testset "Test_Straight_Flush" begin
    hands_1 = Hands([ 1  2  3  4  5  6  7;
                      5 15 18 29 42 51 31], [0, 0, 0, 0])

    hands_2 = Hands([ 1 2 3 4 5 6 7;
                     52 8 3 4 5 6 7], [0, 0, 0, 0])

    hands_3 = Hands([ 1  2 26 25 24 23 22;
                     13 21 26 25 24 23 22], [0, 0, 0, 0])

    hands_4 = Hands([ 1 14 27 40  2  3  4;
                     13 26 27 40  2  3  4], [0, 0, 0, 0])

    @test Straight_Flush(hands_1) == [1]
    @test Straight_Flush(hands_2) == [2]
    @test Straight_Flush(hands_3) == [1, 2]
end;