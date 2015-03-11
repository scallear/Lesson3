require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'random_string' 

helpers do
  def calculate_total(cards)
    arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    arr.select{|element| element == 'A'}.count.times do
      break if total <= 21
      total -= 10
    end

    total
  end
  
  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end
  
    value = case card[1]
      when 'J' then 'jack'
      when 'Q' then 'queen'
      when 'K' then 'king'
      when 'A' then 'ace'
      else card[1]
    end
    
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card'>"
  end
  
  def winner(msg) #use this type to dry up code
    @hit_or_stay_buttons = false
    @success = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
  end
  
end

before do
  @hit_or_stay_buttons = true
end

get '/'do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  #deck
  suit = ['D', 'H', 'C', 'S']
  face = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suit.product(face).shuffle!
  
  #player_cards
  session[:player_cards] = []
  
  #dealer_cards
  session[:dealer_cards] = []
  
  #deal
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == 21
    @success = "Congratulations! #{session[:player_name]} hit balckjack."
    @hit_or_stay_buttons = false
  elsif player_total > 21
    @error = "Sorry, #{session[:player_name]} busted."
    @hit_or_stay_buttons = false
    
  end
  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} chose to stay"
  @hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  @hit_or_stay_buttons = false
  
  dealer_total = calculate_total(session[:dealer_cards])
  
  if dealer_total == 21
    @error = "Sorry, dealer hit blackjack."
  elsif dealer_total > 21
    @success = "Congratulations, dealer busted. #{session[:player_name]} won!"
  elsif dealer_total >= 17
    redirect '/game/compare'
  else
    @dealer_hit_button = true
  end
    
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @hit_or_stay_buttons = false
  
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:delaer_cards])
  
  if player_total < dealer_total
    @error = "Sorry, #{session[:player_name]} lost."
  elsif dealer_total < player_total
    @success = "Congratulations, #{session[:player_name]} won."
  else
    @success = "It's a tie."
  end
  
  erb :game
end