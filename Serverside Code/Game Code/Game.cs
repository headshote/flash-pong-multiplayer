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
        public float x;
        public float y;

        //location last state update
        public float oldX = 0;
        public float oldY = 0;

        public bool rightPressed;
        public bool leftPressed;

        public Player()
        {
            this.rightPressed = false;
            this.leftPressed = false;
        }
	}

	[RoomType("MPPongCode")]
	public class GameCode : Game<Player> 
    {
        private DateTime oldTickTime = new DateTime();
        private DateTime oldStateTime = new DateTime();
        private TimeSpan timeDiff = new TimeSpan();
        private bool doState = false;

		// This method is called when an instance of your the game is created
		public override void GameStarted() 
        {
			// anything you write to the Console will show up in the 
			// output window of the development server
			Console.WriteLine("Game is started: " + RoomId);

            //Timers 
            oldStateTime = DateTime.Now;
            oldTickTime = DateTime.Now;

            AddTimer(tick, 25);
			
		}

		// This method is called when the last player leaves the room, and it's closed down.
		public override void GameClosed() 
        {
			Console.WriteLine("RoomId: " + RoomId);
		}

        //With this fcn we can control permissins to join our room
        public override bool AllowUserJoin(Player player)
        {
            if (PlayerCount + 1 > 2) //In case max number of users in room achieved
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

            if (PlayerCount <= 1) //First player joins
            {
                player.Name = "First";
                player.x = 332.15F;
                player.y = 474.10F;
            }
            else //player two joins
            {
                player.Name = "Second";
                player.x = 339.95F;
                player.y = 12.75F;
            }
             // this is how you broadcast a message to all players connected to the game
            Broadcast("UserJoined", player.Id, player.Name, player.x, player.y);             

            Message infoMessage = Message.Create("info");

            infoMessage.Add(player.Id);

            foreach( Player guy in Players )
            {
                if( guy != player)
                    infoMessage.Add( guy.Id, guy.x, guy.y, guy.rightPressed, guy.leftPressed, guy.Name);
            }
            player.Send(infoMessage);
		}

		// This method is called when a player leaves the game
		public override void UserLeft(Player player) 
        {
			Broadcast("UserLeft", player.Id);
		}

		// This method is called when a player sends a message into the server code
		public override void GotMessage(Player player, Message message)
        {
            DateTime nowTime = DateTime.Now;
            timeDiff = oldStateTime - nowTime;
            int msTimeDiff = timeDiff.Milliseconds;

			switch(message.Type) 
            {				
                case "leftUp":
                    Broadcast("leftUp", player.Id);
                    player.leftPressed = false;
                    break;
                case "leftDown":
                    Broadcast("leftDown", player.Id);
                    player.leftPressed = true;
                    break;
                case "rightUp":
                    Broadcast("rightUp", player.Id);
                    player.rightPressed = false;
                    break;
                case "rightDown":
                    Broadcast("rightDown", player.Id);
                    player.rightPressed = true;
                    break;
			}
            Console.WriteLine(message.Type);
		}
		
        //Called every 25 ms, main game logic here
        private void tick()
        {
            //Get the time elapsed since the last tick
            DateTime nowTime = DateTime.Now;
            timeDiff = nowTime - oldTickTime;
            //The difference in ms
            int msTimeDiff = timeDiff.Milliseconds;
            //Renew the time of the last update
            oldTickTime = nowTime;

            //Move each player
            foreach (Player guy in Players)
            {
                if (guy.rightPressed)
                {
                    guy.x += msTimeDiff / 5;
                }
                if (guy.leftPressed)
                {
                    guy.x -= msTimeDiff / 5;
                }
            }

            //Sending state update message every other tick
            if (doState)
            {
                //Time since last state update
                timeDiff = nowTime - oldStateTime;
                msTimeDiff = timeDiff.Milliseconds;

                Message stateUpdateMessage = Message.Create("state");
                stateUpdateMessage.Add(msTimeDiff);

                foreach (Player guy in Players)
                {
                    //Send update message containing only players tha moved
                    if (guy.oldX != guy.x )
                    {
                        stateUpdateMessage.Add(guy.Id, guy.x);
                        guy.oldX = guy.x;
                    }
                }
                if ( stateUpdateMessage.Count >= 3)
                    Broadcast(stateUpdateMessage);
                oldStateTime = nowTime;
                doState = false;
            }
            else
            {
                doState = true;
            }
        }
	}
}
