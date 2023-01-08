using SimpleWebsockets
using Probker
using JSON
using Logging
using Revise 

revise(Probker)
io = open("log.txt", "w+")
logger = SimpleLogger(io)
with_logger(logger) do
    @info("a context specific log message")
end

#& What should I do? I should probably code the javascript logic the same way as I code the Juila 
#& logic.

#& I should correct the Game struct. The collect approach is bad and could hide bugs.

function Extract_Game_And_Load_Into_Struct(game_dict)


    extracted_game = game(
        game_dict["number_of_players"],
        game_dict["player_cards"],
        game_dict["shared_cards"][1] == 0 ? [0] : game_dict["shared_cards"][1:3],
        game_dict["shared_cards"][4],
        game_dict["shared_cards"][5],
        [0 0],
        collect(setdiff(1:52,   game_dict["player_cards"],
                                game_dict["shared_cards"][1:3],
                                game_dict["shared_cards"][4],
                                game_dict["shared_cards"][5])),
        game_dict["simulations"])



    return extracted_game
end

#& I should correct the problem in the java script file! And put aces in the bottom. Yes! That is


# function Process_Game(game)
#     if 

# end
game(2, [1,2,3,4], [5,6,7], 0, 0, [0 0], collect(8:52), 1000)

server = WebsocketServer()
listen(server, :client) do ws   
    listen(ws, :message) do message
        println(@__LINE__)
        try
            println("no error here!")
            game_dict = JSON.parse(message)
            game = Extract_Game_And_Load_Into_Struct(game_dict)
            println(game)
            probabilities = Simulate(game)
            probabilities_JSON = JSON.json(probabilities)
            send(ws, probabilities_JSON)
            flush(io)
        catch err
            @info err          
            flush(io)
            send(ws, "Could not run command")
            flush(io)
        end
    end
end

function echo(val)
    return val
end

@async serve(server, 8081)