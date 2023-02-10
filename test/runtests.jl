using Test
using Coverage
using Random
using StatsBase
using Probker
using Profile
using PProf
using JET
revise(Probker)

########################################################
##########              PROFILING             ##########
########################################################
Profile.clear()
@profile Simulate(Game(2, [13,25,0,0,0,0,0,0,0], 10000))
pprof()

@testset "Simulate_Hidden_Cards " begin
    test_game_flop = Game(8, [13, 14, 15, 1, 37, 32, 21, 22, 23, 27, 28, 20, 43, 49, 0, 0, 51, 52, 26, 47, 41], 10000)
    @test Card_Duplication(Sample(test_game_flop)) == false broken = true
end

@testset "Test_Probker.Determine_Win" begin
    # royal flush vs four kind
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

    player_cards_11 = [23, 13, 5, 51]
    shared_cards_11 = [3, 9, 10, 42, 38]

    player_cards_12 = [48, 51, 1, 11+13+13]
    shared_cards_12 = [1+13+13,3+13,13,4,13+13+13+5]

    hands_1 = Hands([   47 11 21 40 39 14 34;
                        26  7 21 40 39 14 34;
                        17 38 21 40 39 14 34;])



    @test Probker.Determine_Win(Cards_To_Hands(player_cards_10, shared_cards_10))[1] == [1]
    @test Probker.Determine_Win(Cards_To_Hands(player_cards_9, shared_cards_9))[1] == [1]
    @test Probker.Determine_Win(Cards_To_Hands(player_cards_1, shared_cards_1))[1] == [1]
    @test Probker.Determine_Win(Cards_To_Hands(player_cards_2, shared_cards_2))[1] == [2]
    @test Probker.Determine_Win(Cards_To_Hands(player_cards_3, shared_cards_3))[1] == [2]
    @test Probker.Determine_Win(Cards_To_Hands(player_cards_4, shared_cards_4))[1] == [1]
    @test Probker.Determine_Win(Cards_To_Hands(player_cards_5, shared_cards_5))[1] == [2]
    @test Probker.Determine_Win(Cards_To_Hands(player_cards_6, shared_cards_6))[1] == [1]
    @test Probker.Determine_Win(Cards_To_Hands(player_cards_7, shared_cards_7))[1] == [2]
    @test Probker.Determine_Win(Cards_To_Hands(player_cards_8, shared_cards_8))[1] == [1]
    @test Probker.Determine_Win(Cards_To_Hands(player_cards_11, shared_cards_11))[1] == [2]
    @test Probker.Determine_Win(Cards_To_Hands(player_cards_12, shared_cards_12))[1] == [2]
    @test Probker.Determine_Win(hands_1)[1] == [1]
    
end

@testset "Test checker functions" begin
    hands_1 = Hands([    1 2 3 4 5 8 9;
                        11 9 3 4 5 8 9])
    hands_2 = Hands([1 3 5 7 9 11 13;
                     2 4 5 7 9 11 13])
    @test Probker.Check_Straight(hands_1::Hands) == true
    @test Probker.Check_Straight(hands_2::Hands) == false

end


@testset "Test_High_Card" begin
    hands_1 = Hands([   13  2 4 17 19 31 34;
                        12 11 4 17 19 31 34])

    hands_2 = Hands([   13  2 4 17 19 31 34;
                        26 11 4 17 19 31 34])

    hands_3 = Hands([   13 24 4 17 19 31 34;
                        26 11 4 17 19 31 34])

    hands_4 = Hands([   13  1  4 17 19 31 34;
                        26  2  4 17 19 31 34;
                        39  3  4 17 19 31 34;
                        52 12  4 17 19 31 34;
                        12  5  4 17 19 31 34;
                        24  6  4 17 19 31 34;
                        14  7  4 17 19 31 34;
                        15  8  4 17 19 31 34;
                        16  9  4 17 19 31 34])
                        
    @test High_Card(hands_1) == [1]
    @test High_Card(hands_2) == [2]
    @test High_Card(hands_3) == [1, 2]
    @test High_Card(hands_4) == [4] 
end

@testset "Test_Two_Kind" begin
    hands_1 = Hands([   13 26  1 14 18 33 42;
                        5 18  1 14 18 33 42])
    hands_2 = Hands([   13  1  7 20 26 31 47;
                        39 12  7 20 26 31 47])
    hands_3 = Hands([   13  1  7 20 26 31 43;
                        39  2  7 20 26 31 43])
    hands_4 = Hands([   1 2 13 12 25 33 46;
                        14 15 13 12 25 33 46;
                        27 28 13 12 25 33 46;
                        40 41 13 12 25 33 46;
                        3 4 13 12 25 33 46;
                        16 17 13 12 25 33 46;
                        29 30 13 12 25 33 46;
                        42 43 13 12 25 33 46;
                        5 6 13 12 25 33 46])
    hands_5 = Hands([   1  2 3 4 19 20 21;
                        14 15 3 4 19 20 21])
    
    @test Two_Kind(hands_1) == [1]
    @test Two_Kind(hands_2) == [2]
    @test Two_Kind(hands_3) == [1, 2]
    @test Two_Kind(hands_4) == collect(1:9)
    @test Two_Kind(hands_5) == "non-existent"
end

@testset "Test_Two_Pairs" begin
    hands_1 = Hands([   13 26  1 14 18 33 42;
                        5 18  1 14 18 33 42])
    hands_2 = Hands([   13  1  7 20 26 31 47;
                        39 12  7 20 26 31 47])
    hands_3 = Hands([   13  1  7 20 26 31 43;
                        39  2  7 20 26 31 43])
    hands_4 = Hands([   1 2 13 12 25 33 46;
                        14 15 13 12 25 33 46;
                        27 28 13 12 25 33 46;
                        40 41 13 12 25 33 46;
                        3 4 13 12 25 33 46;
                        16 17 13 12 25 33 46;
                        29 30 13 12 25 33 46;
                        42 43 13 12 25 33 46;
                        5 6 13 12 25 33 46])
    hands_5 = Hands([   1 2 3 4 19 20 21;
                        14 15 3 4 19 20 21 ])


    @test Two_Pairs(hands_1) == [1]
    @test Two_Pairs(hands_2) == [2]
    @test Two_Pairs(hands_3) == [1, 2]
    @test Two_Pairs(hands_4) == collect(1:9)
    @test Two_Pairs(hands_5) == "non-existent"
end

@testset "Test_Three_Kind" begin
    hands_1 = Hands([   13 26 39 1 15 17 38;
                        12 25 39 1 15 17 38])
    hands_2 = Hands([   13  1 14 26 39 3 7;
                        52 27 14 26 39 3 7])
    hands_3 = Hands([   13  1 14 26 39 3 7;
                        52 12 14 26 39 3 7])
    hands_4 = Hands([   1 2 3 17 18 19 38;
                        14 15 3 17 18 19 38])
    hands_5 = Hands([   1 2 3 17 18 19 38;
                        14 15 3 17 18 19 38
                        4 6 3 17 18 19 38;
                        9 10 3 17 18 19 38
                        27 28 3 17 18 19 38;
                        50 30 3 17 18 19 38
                        34 38 3 17 18 19 38;
                        42 43 3 17 18 19 38
                        16 29 3 17 18 19 38])
    
    @test Three_Kind(hands_1) == [1]
    @test Three_Kind(hands_2) == [1, 2]
    @test Three_Kind(hands_3) == [2]
    @test Three_Kind(hands_4) == "non-existent"
    @test Three_Kind(hands_5) == [9]
end

@testset "Test_Straight" begin
    hands_1 = Hands([    1  2  3  4 18 50 51;
                        14 15  3  4 18 50 51])
    hands_2 = Hands([   17 18 19 20 34  1  2;
                        35 49 19 20 34  1  2])
    hands_3 = Hands([    1  2  3 18 19 20 21;
                        14 15  3 18 19 20 21])
    hands_4 = Hands([   13 11  8 22 17 27 42;
                        28 39  8 22 17 27 42])

    @test Straight(hands_1) == [1, 2]
    @test Straight(hands_2) == [2]
    @test Straight(hands_3) == "non-existent"
    @test Straight(hands_4) == [2]
end

@testset "Test_Flush" begin
    hands_1 = Hands([   1 2 3 4 5 50 52;
                        6 7 3 4 5 50 52])
    hands_2 = Hands([   1 2 52 51 50 49 48;
                        12 13 52 51 50 49 48])
    hands_3 = Hands([   1 2 3 14 15 16 43;
                        5 6 3 14 15 16 43])
    @test Flush(hands_1) == [2]
    @test Flush(hands_2) == [1, 2]
    @test Flush(hands_3) == "non-existent"
    
end


@testset "Test_Full_House" begin

    hands_1 = Hands([   14  2 12 25  3 16 29;
                        4 38 12 25  3 16 29])
    hands_2 = Hands([   1  2 12 25  3 16 29;
                        17 13 12 25  3 16 29])
    hands_3 = Hands([   1 15  3 18 19  7 22;                   
                        14 28 3 18 19 7 22])
    hands_4 = Hands([   47 11 21 40 39 14 34;
                        26  7 21 40 39 14 34;
                        17 38 21 40 39 14 34;])
    
    
    
    @test Full_House(hands_1) == [2]
    @test Full_House(hands_2) == [1, 2]
    @test Full_House(hands_3) == "non-existent"
    @test Full_House(hands_4) == [1]
    
end

@testset "Test_Four_Kind" begin
    
    hands_1 = Hands([   1 14 27 40 26 3 5;
                        2 15 27 40 26 3 5])
    hands_2 = Hands([   12 11 5 18 31 44 3;
                        13 1 5 18 31 44 3])    
    hands_3 = Hands([   1 2 3 16 29 42 12;
                        10 11 3 16 29 42 12])
    hands_4 = Hands([   1 14 2 16 42 9 19;
                        3 15 2 16 42 9 19])
    @test Four_Kind(hands_1) == [1]
    @test Four_Kind(hands_2) == [2]
    @test Four_Kind(hands_3) == [1, 2]
    @test Four_Kind(hands_4) == "non-existent"
end

@testset "Test_Straight_Flush" begin
    hands_1 = Hands([ 1  2  3  4  5  6  7;
                      5 15 18 29 42 51 31])

    hands_2 = Hands([ 1 2 3 4 5 6 7;
                     52 8 3 4 5 6 7])

    hands_3 = Hands([ 1  2 26 25 24 23 22;
                     13 21 26 25 24 23 22])

    hands_4 = Hands([ 1 14 27 40  2  3  4;
                     13 26 27 40  2  3  4])

    @test Straight_Flush(hands_1) == [1]
    @test Straight_Flush(hands_2) == [2]
    @test Straight_Flush(hands_3) == [1, 2]
    @test Straight_Flush(hands_4) == "non-existent"
end;





#~ I should talk with Jonas about the piecharts

#& Determine win should say which kind of hand won. Do we care about the 
#& the hands that the players got when they did not win?

#& The key issue here is whether we should condition the probability on the 
#& fact that the player won. What do I lose by not doing this? If a player 
#& gets a good hand then that could be interesting the see the probability of
#& that. I shou

#& To get either result I have to provide a number for each kind of hand
#& for each kind of player, where each number is the 
#& number of times the hand was given. Should I mark when
#& it is the winning hand? Yes at least I should make it 
#& so that that there are some kind of measure that 
#& keeps track of how we should which hand won.
#& If I do not do this then the measure can seem a 
#& little meaningless. I think that giving two pie charts 
#& would be a good course of action. 

#& Yes that is the way to go I think. I should also think of which chart 
#& I could use. 
    #& pie
    #& spider and radar could actually be very good
        #& I think that I will make 
        #& one of these. Being in the outer ring would means 
        #& 100% chance of getting that hand.
    #& stacked polar chart
    
#& The conditional chance is always lower than the 
#& non-conditional chance right? 
    #&