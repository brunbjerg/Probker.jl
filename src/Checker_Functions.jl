function Check_Straight_Flush(hands::Hands)
    for player in hands.players
        # five_in_suit(hands.hands[player, :]) ? println("yes") : println("no")
        five_in_suit(hands.hands[player, :]) || continue 
        for i in 0:3
            suit = findall(x -> x in 1 + (13 * i):13 + (13 * i), hands.hands[player, :])
            len_suit = length(suit)
            if len_suit in [0, 1, 2]
                continue
            elseif len_suit in [3, 4]
                break
            elseif len_suit in [5, 6, 7]
                sorted = sort(hands.hands[player, suit])
                count = 1
                13 * (i + 1) in sorted && (sorted = [13 * i; sorted])
                for c in 1:length(sorted) - 1
                    sorted[c] == sorted[c + 1] - 1 ? count += 1 : count = 1
                    count == 5 && return true
                end
            else
                throw(ErrorException)
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
    for player in hands.players
        sorted = unique(sort(hands.sorted[player, :]))
        count = 1
        13 in sorted && (sorted = [0; sorted] )
        for c in 1:length(sorted) - 1
            sorted[c] == sorted[c + 1] - 1 ? count += 1 : count = 1
            count == 5 && return true
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
