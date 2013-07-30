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
        public float oldX;
        public float oldY;

        //Dimensions
        public const float width= 154.30F;
        public const float height = 29.15F;

        public bool rightPressed;
        public bool leftPressed;

        public Player()
        {
            this.oldX = 0;
            this.oldY = 0;
            this.rightPressed = false;
            this.leftPressed = false;
        }
	}

    public class Ball
    {
        public float x;
        public float y;
        public float xVelocity;
        public float yVelocity;
        public const float width = 27.10F;
        public const float height = 24.80F;

        public Ball() : this(300.0F, 250.0F, 5.0F, 5.0F)
        {
            
        }

        public Ball(float X, float Y, float xv, float yv)
        {
            this.x = X;
            this.y = Y;
            this.xVelocity = xv;
            this.yVelocity = yv;
        }
    }

	[RoomType("MPPongCode")]
	public class GameCode : Game<Player> 
    {
        //Parameters of game stage
        public float stageWidth = 790.0F;
        public float stageHeight = 600.0F;

        //For time measurement
        private DateTime oldTickTime = new DateTime();
        private DateTime oldStateTime = new DateTime();
        private TimeSpan timeDiff = new TimeSpan();
        
        //Ball object
        Ball ball;

        /*******************************************************************
         *************MAIN FUNCTIONS, CONTAIN GENERAL GAME LOGIC************
         *******************************************************************/

        // This method is called when an instance of your the game is created
		public override void GameStarted() 
        {
			// anything you write to the Console will show up in the 
			// output window of the development server
			Console.WriteLine("Game is started: " + RoomId);

            //Timers 
            oldStateTime = DateTime.Now;
            oldTickTime = DateTime.Now;

            ball = new Ball();

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

            //addd info  about current player( that has just joined)
            infoMessage.Add(player.Id);
            //add all of the players in the scene
            foreach( Player guy in Players )
            {
                if( guy != player)
                    infoMessage.Add( guy.Id, guy.x, guy.y, guy.rightPressed, guy.leftPressed, guy.Name);
            }
            //For ball
            infoMessage.Add(ball.x, ball.y, ball.xVelocity, ball.yVelocity);

            //send it to player that has just joined
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
                case "hitBall":    //got msg about collision from client
                    processCollision(player);                                     
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
                processCollision(guy);
                if (guy.rightPressed)
                {
                    if (guy.x >= this.stageWidth - Player.width) //keep players in bounds of stage
                        guy.x = this.stageWidth - Player.width;
                    else
                        guy.x += msTimeDiff / 2;
                }
                if (guy.leftPressed)
                {
                    if (guy.x <= 0)//keep players in bounds of stage
                        guy.x = 0;
                    else
                        guy.x -= msTimeDiff / 2;
                }
            }

            //Move ball
            this.moveBall();

            //Sending state update message every tick
            doState(nowTime, msTimeDiff);                     
        }

        /**********************************************************************************************
         *********HELPER FUNCTIONS (CALLED BY MAIN FUNCTIONS, DOING SPECIFIC LOWER LEVEL STUFF)********
         **********************************************************************************************/

        //Handles movement of ball and it's collisions with WALLS ONLY
        //Called regularly by tick()
        private void moveBall()
        {
            //Bouncing off side walls
            if (ball.x <= 0)
            {
                wasHit();
                ball.x = 0;
                ball.xVelocity *= -1;
            }
            else if (ball.x >= this.stageWidth - Ball.width)
            {
                wasHit();
                ball.x = this.stageWidth - Ball.width;
                ball.xVelocity *= -1;
            }

            //Bouncing off top and bottom parts of scene
            if (ball.y <= 0)
            {
                wasHit();
                ball.y = 0;
                ball.yVelocity *= -1;
            }
            else if (ball.y >= this.stageHeight - Ball.height)
            {
                wasHit();
                ball.y = this.stageHeight - Ball.height;
                ball.yVelocity *= -1;
            }
            //Move ball
            ball.x += ball.xVelocity;
            ball.y += ball.yVelocity;
        }

        //Will change angle of ball movement based on which part of boaard was hit
        private void checkHitLocation(Player player)
        {
            float hitPercent;
	        float ballPosition = ball.x - player.x;
	        hitPercent = (ballPosition / (Player.width - Ball.width) ) - 0.5F;
	        ball.xVelocity = hitPercent * 5;
	        ball.yVelocity *= 1.0005F; //slightly increase speed with each hit
        }

        //For serverside double checking of collisions
        private bool ballCollision(Player player)
        {
            //Determone coords of centers of board and ball
            float centerBallY = ball.y + Ball.height/2;
            float centerBoardY = player.y + Player.height/2;
            float centerBallX = ball.x + Ball.width / 2;
            float centerBoardX = player.x + Player.width / 2;
            //measure distances between centers
            if (Math.Abs(centerBallY - centerBoardY) <= (Ball.height / 2 + Player.height / 2))
            {
                if (Math.Abs(centerBallX - centerBoardX) <= (Ball.width / 2 + Player.width / 2))
                 
                 {
                   return true;
                 }
            }
            return false;
        }

        //Creates game state update msg and broadcasts it to all players
        private void doState(DateTime nowTime, int msTimeDiff)
        {     
            Message stateUpdateMessage = Message.Create("state");
            stateUpdateMessage.Add(msTimeDiff); //add time difference between state update msgs on serverside
            foreach (Player guy in Players)
            {
                //Send update message containing only players tha moved
                if (guy.oldX != guy.x)
                {
                    stateUpdateMessage.Add(guy.Id, guy.x);
                    guy.oldX = guy.x;
                }
            }
            //for ball position
            stateUpdateMessage.Add(ball.x, ball.y, ball.xVelocity, ball.yVelocity);

            //Broadcasting curent state of the game to everyone in the room
            Broadcast(stateUpdateMessage);
            //Setting time since last state update (and tick at the same time)
            oldStateTime = nowTime;
        }

        //Will be called every time ball collides with anything;
        private void wasHit()
        {
            //Tell everyone that ball collided with something, and send tick time interval, ball coords and params
            Broadcast("hitBall", ball.x, ball.y, ball.xVelocity, ball.yVelocity);
        }

        //Fcn that simulates rudimentary physics for ball bouncing off boards
        private void processCollision(Player player)
        {
            if (this.ballCollision(player)) //Double check collision on server
            {
                wasHit();
                this.checkHitLocation(player); //Changes angle of movement based on which part of the board was hit by ball
                if (player.Name == "First")
                    ball.y = player.y - Ball.height - Player.height / 2; //placing ball on top of player1's paddle to avoid derping
                else if (player.Name == "Second")
                    ball.y = player.y + Player.height + Ball.height / 2; //placing ball below of player2's paddle to avoid derping
                ball.yVelocity *= -1; //Bounce
            }   
        }
	}
}
