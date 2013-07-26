using System;
using System.Collections.Generic;
using System.Text;
using System.Collections;
using PlayerIO.GameLibrary;
using System.Drawing;

namespace MPPongCode
{
	public class Player : BasePlayer 
    {
		public string Name;
	}

	[RoomType("MPPongCode")]
	public class GameCode : Game<Player> 
    {
        DateTime oldTickTime = new DateTime();
        DateTime oldStateTime = new DateTime();

		// This method is called when an instance of your the game is created
		public override void GameStarted() 
        {
			// anything you write to the Console will show up in the 
			// output window of the development server
			Console.WriteLine("Game is started: " + RoomId);

            //Timers 
            oldStateTime = DateTime.Now;
            oldTickTime = DateTime.Now;

            AddTimer(tick, 50);
			
		}

		// This method is called when the last player leaves the room, and it's closed down.
		public override void GameClosed() 
        {
			Console.WriteLine("RoomId: " + RoomId);
		}

        public override bool AllowUserJoin(Player player)
        {
            if (PlayerCount + 1 > 2)
            {
                Console.WriteLine("AllowUserJoin returned false ->room is full");
                player.Send("disconnect");
                return false;
            }
            return base.AllowUserJoin(player);
        }

		// This method is called whenever a player joins the game
		public override void UserJoined(Player player) 
        {
            
             // this is how you send a player a message
             player.Send("hello");

             // this is how you broadcast a message to all players connected to the game
             Broadcast("UserJoined", player.Id);             
		}

		// This method is called when a player leaves the game
		public override void UserLeft(Player player) 
        {
			Broadcast("UserLeft", player.Id);
		}

		// This method is called when a player sends a message into the server code
		public override void GotMessage(Player player, Message message)
        {
			switch(message.Type) 
            {
				// This is how you would set a players name when they send in their name in a 
				// "MyNameIs" message
				case "MyNameIs":
					player.Name = message.GetString(0);
					break;
			}
		}
		
        //Called every 50 ms
        private void tick()
        {

        }
	}
}
