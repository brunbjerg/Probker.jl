function Check_Straight_Flush(hands::Hands)
    player_scores = zeros(Int, maximum(hands.players))
    for player in hands.players
        straight_counter = 1
        #~ Start here. Go card by card instead and also update the Straight_Flush
        #~ function. And change the function names to be all lowercase.

        #& Hmm... Are we sure that this function is wrong? Yes it must be.
        ace_updated_hand = copy(hands.hands[player, :])
        if 13 in ace_updated_hand
            push!(ace_updated_hand, 0)
        end
        for card = 1:length(ace_updated_hand) - 1
            #& Here one is sorted and one is not. That means that we do not look at the same cards. I need to completely rethink this.
            #& I think that I should go one card at a time.

            #& This means that there is also an error in the Straight_Flush function. 
            if ace_updated_hand[card] == ace_updated_hand[card + 1] + 1 && any(issubset([hands.hands[card], hands.hands[card + 1]], (1 + i*13 :13 + i*13) ) for i in 0:3)
                straight_counter += 1
                if straight_counter == 5 #@ && any(count(x -> x in (1 + i*13 :13 + i*13), hands.hands[player, :]) >= 5 for i in 1:4)
                    
                    player_scores[player] = copy(ace_updated_hand[card])
                    println(hands.hands)
                    println(player_scores)
                    return true
                end
            else
                straight_counter = 1
            end
        end
    end
    return false
end

function Check_Four_Kind(hands::Hands)
    for player in hands.players
        maximum(counts(hands.sorted[player, :])) == 4 && return true
    end
    return false
end

function Check_Full_House(hands::Hands)
    for player in hands.players
        sum(sort(counts(hands.sorted[player, :]), rev = true)[1:2]) == 5 && return true
    end
    return false        
end

function Check_Flush(hands::Hands)
    for player in hands.players
        for i in 0:3
            if count(x -> x in (1 + i*13 :13 + i*13), hands.hands[player, :]) >= 5 
                return true
            end
        end
    end
    return false
end

function Check_Straight(hands::Hands)
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
                    return true
                end
            else
                count = 1
            end
        end
    end
    return false
end


function Check_Three_Kind(hands::Hands)
    for player in hands.players
        if any(counts(hands.sorted[player, :]) .>= 3)
            return true
        end 
    end
    return false
end

function Check_Two_Pair(hands::Hands)
    for player in hands.players
        sum(sort(counts(hands.sorted[player, :]), rev = true)[1:2]) == 4 && return true
    end
    return false        
end

function Check_Two_Kind(hands::Hands)
    for player in hands.players
        if any(counts(hands.sorted[player, :]) .>= 2)
            return true
        end 
    end
    return false
end
