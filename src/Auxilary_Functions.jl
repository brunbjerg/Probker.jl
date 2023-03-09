function Cards_To_Hands(player_cards, shared_cards, folded_cards)
    hands = zeros(Int64, length(player_cards) ÷ 2, 7)
    for player = 1:length(player_cards) ÷ 2
        for card = 1:7
            if card in [1, 2]
                hands[player, card] = player_cards[(player - 1) * 2 + card]
            else
                hands[player, card] = shared_cards[card - 2]
            end
        end
    end
    return Hands(hands, folded_cards)
end

function five_in_suit(hand)
    a = 0
    for i = 1:4
        a = searchsortedfirst(hand, 13 * i) - a
        a == 4 && return false
        13 * i in hand ? c = 5 : c = 6
        a >= c && return true
    end
    return false
end

