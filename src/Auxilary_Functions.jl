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