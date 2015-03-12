require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'random_string' 
#constants

#helpers

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
      break if total <= BLACKJACK
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
  
  def winner!(msg)
    @play_again = true
    @hit_or_stay_buttons = false
    @success = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
  end
  
  def loser!(msg)
    @play_again = true
    @hit_or_stay_buttons = false
    @error = "<strong>#{session[:player_name]} loses.</strong> #{msg}"
  end
  
  def tie!(msg)
    @play_again = true
    @hit_or_stay_buttons = false
    @success = "<strong>#{session[:player_name]} and the dealer tied!</strong> #{msg}"
  end
end

#filters

before do
  @hit_or_stay_buttons = true
  @show_money = true
end

#routes

get '/' do
  @show_money = false
  erb :intro
end

get '/new_player' do
  @show_money = false
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty? 
    @error = "You must enter your name to continue."
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  redirect '/place_bet'
end

get '/place_bet' do
  @show_money = false
  session[:player_money] = 200
  erb :place_bet
end

post '/place_bet' do
  session[:player_money] -= params[:player_bet].to_i
  redirect '/game'
end

get '/game' do
  suit = ['D', 'H', 'C', 'S']
  face = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suit.product(face).shuffle!
  
  session[:player_cards] = []
  
  session[:dealer_cards] = []
  
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK
    winner!("#{session[:player_name]} hit balckjack.")
    @hit_or_stay_buttons = false
  elsif player_total > BLACKJACK
    loser!("#{session[:player_name]} busted.")
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
  
  if dealer_total == BLACKJACK
    loser!("The dealer hit blackjack.")
  elsif dealer_total > BLACKJACK
    winner!("Congratulations, dealer busted. #{session[:player_name]} won!")
  elsif dealer_total >= DEALER_HIT
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
  dealer_total = calculate_total(session[:dealer_cards])
  
  if player_total < dealer_total
    loser!("Final Score: #{session[:player_name]} - #{player_total}, Dealer - #{dealer_total}")
  elsif dealer_total < player_total
    winner!("Final Score: #{session[:player_name]} - #{player_total}, Dealer - #{dealer_total}")
  else
    tie!("Final Score: All - #{player_total}")
  end
  
  erb :game
end

get '/game_over' do
  erb :game_over
end