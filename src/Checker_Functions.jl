function Check_Straight_Flush(hands::Hands)
    support_function = [0, 1, 2, 3, 4, 5, 6, 7]
    for player in 1:hands.players   
        temp_hands = hands.sorted[player, :]
        if 13 in temp_hands
            push!(temp_hands, 0)
        else 
            push!(temp_hands, -1)
        end
        temp_hands .+= support_function 
        if 13 in hands.sorted[player, :] && length(findall(x -> x == 7, temp_hands)) == 5
            break
        elseif maximum(counts(temp_hands)) >= 5
            for i in 0:3
                if count(x -> x in (1 + i*13 :13 + i*13), hands.hands[player, :]) >= 5 
                    return true
                end
            end
        end
    end
    return false
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

function Check_Flush(hands::Hands)
    for player in 1:hands.players
        for i in 0:3
            if count(x -> x in (1 + i*13 :13 + i*13), hands.hands[player, :]) >= 5 
                return true
            end
        end
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
        if 13 in hands.sorted[player, :] && length(findall(x -> x == 7, temp_hands)) == 5
            break
        else
            maximum(counts(temp_hands)) >= 5 && return true
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

function Check_Two_Pair(hands::Hands)
    for player in 1:hands.players
        sum(sort(counts(hands.sorted[player, :]), rev = true)[1:2]) == 4 && return true
    end
    return false        
end

function Check_Two_Kind(hands::Hands)
    for player in 1:hands.players
        if any(counts(hands.sorted[player, :]) .>= 2)
            return true
        end 
    end
    return false
end
