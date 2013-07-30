package {
	import playerio.*
	import flash.display.*;
	import flash.events.*;
 	import flash.ui.*;
	import flash.geom.ColorTransform;
	
	public class MP_Pong extends MovieClip
	{
		var connection:Connection;
		//Player info
		var players:Array;
		var myBoard:Player;
		var myId:int;	
		//Ball
		var ball:Ball;
		//Time at the last frame
		var oldTime:Number = (new Date()).getTime();
		//Time at the last state update
		var oldStateTime:Number;
		var serverTimeDiff:int;
		//Sound
		var hitSound:Hit;
		
		function MP_Pong()
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
			oldStateTime = 0;
			stop();			
			
			hitSound = new Hit();
			
			PlayerIO.connect(
				stage,								//Referance to stage
				"multiplayer-pong-jed5uk4mnkx6pgpynxeva",			//Game id (Get your own at playerio.com)
				"public",							//Connection id, default is public
				"GuestUser" + Math.floor(Math.random()*1000).toString(),	//Username
				"",									//User auth. Can be left blank if authentication is disabled on connection
				null,								//Current PartnerPay partner.
				handleConnect,						//Function executed on successful connect
				handleError							//Function executed if we recive an error
			);   
			players = new Array();
		}	
		
		//init function, called once class is added to stage
		function init(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			stage.frameRate = 40;
		}
		
		private function handleConnect(client:Client):void
		{
			trace("Sucessfully connected to player.io");
			
			//Set developmentsever (Comment out to connect to your server online)
			//client.multiplayer.developmentServer = "localhost:8184";
			
			//Create pr join the room test
			client.multiplayer.createJoinRoom(
				"test",								//Room id. If set to null a random roomid is used
				"MPPongCode",						//The game type started on the server
				true,								//Should the room be visible in the lobby?
				{},									//Room data. This data is returned to lobby list. Variabels can be modifed on the server
				{},									//User join data
				handleJoin,							//Function executed on successful joining of the room
				handleError							//Function executed if we got a join error
			);
		}
		
		
		private function handleJoin(conn:Connection):void
		{			
			trace("Sucessfully connected to the multiplayer server");
			gotoAndStop(2);	 
			
			
			connection = conn;
			//Add disconnect listener
			connection.addDisconnectHandler(handleDisconnect);
			
			//In case server tells us that we should go away
			connection.addMessageHandler("disconnect", function(m:Message){
				gotoAndStop(3); 
				trace("Disconnected from server.");			 
			})									
			
			//Add message listener for users leaving the room
			connection.addMessageHandler("UserLeft", userLeft)
			
			//Listen to all messages using a private function
			connection.addMessageHandler("*", handleMessages)
			
			//Add event listeners
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased);
			stage.addEventListener(Event.ENTER_FRAME, everyFrame);		
		}
		
		//removes user from stage and from attay of players if he leaves game
		private function userLeft( message:Message)
		{
			removeChild(players[message.getInt(0)])
			delete players[message.getInt(0)];
		}
		
		//main handler for incomming messages from server
		private function handleMessages(message:Message)
		{
			//The time now
			var messageTime:Number = (new Date()).getTime();
			//The time since the last state update, is actually equal to time since last tick
			//but code might be modified on server such that they won't be equal
			var timeStateDiff:Number = messageTime - oldStateTime;
			switch(message.type)
			{
				case "UserJoined": //When user joined, add him to stage on clientside
					players[message.getInt(0)] = new Player();					
					players[message.getInt(0)].x = message.getNumber(2);
					players[message.getInt(0)].y = message.getNumber(3);
					players[message.getInt(0)].rightPressed = false;
					players[message.getInt(0)].leftPressed = false;
					players[message.getInt(0)].pName = message.getString(1);
					if(  message.getString(1) == 'First' ) //Determines which user joined and draws him on top or at the bottom
					{							
							var colorT:ColorTransform = new ColorTransform();						
							colorT.blueOffset = 0;
							colorT.redOffset = 0;
							colorT.greenOffset = 0;
							players[message.getInt(0)].transform.colorTransform = colorT;
					}
					else if(  message.getString(1) == "Second" )
					{
							var colorT:ColorTransform = new ColorTransform();
							colorT.blueOffset = 100;
							colorT.redOffset = -100;
							colorT.greenOffset = 150;							
							players[message.getInt(0)].transform.colorTransform = colorT;
					}
					addChildAt(players[message.getInt(0)],0)					
					break;
				case "info": //Message with info about the current scene, is sent to user once when he connects to server
					var i:int;
					//Get your ID
					myId = message.getInt(0)
					myBoard = players[myId];
					//Load every existing player's data										
					for( i = 0;i<(message.length - 1 - 4)/6;i++)
					{
						if (players[message.getInt(i*6 + 1)] == null )
							players[message.getInt(i*6 + 1)] = new Player();
						players[message.getInt(i*6 + 1)].x = message.getNumber(i*6 + 2);
						players[message.getInt(i*6 + 1)].y = message.getNumber(i*6 + 3);
						players[message.getInt(i*6 + 1)].rightPressed = message.getBoolean(i*6 + 4);
						players[message.getInt(i*6 + 1)].leftPressed = message.getBoolean(i*6 + 5);
						players[message.getInt(i*6 + 1)].pName = message.getString(i*6 + 6);
						if(  message.getString(i*6 + 6) == 'First' ) //Give some distinct color and position at unique place
						{							
								var colorT:ColorTransform = new ColorTransform();						
								colorT.blueOffset = 0;
								colorT.redOffset = 0;
								colorT.greenOffset = 0;
								players[message.getInt(i*6 + 1)].transform.colorTransform = colorT;
						}
						else if(  message.getString(i*6 + 6) == "Second" ) //Give some distinct color and position at unique place
						{
								var colorT:ColorTransform = new ColorTransform();
								colorT.blueOffset = 100;
								colorT.redOffset = -100;
								colorT.greenOffset = 150;							
								players[message.getInt(i*6 + 1)].transform.colorTransform = colorT;
						}
						addChildAt(players[message.getInt(i*6 + 1)],0)
					}
					//Load ball
					i = i*6+1;
					ball = new Ball();
					ball.x = message.getNumber(i);
					ball.y = message.getNumber(i+1);
					ball.xVelocity = message.getNumber(i+2);
					ball.yVelocity = message.getNumber(i+3);
					addChildAt(ball, 0)
					break;
				case "state": //State update sent by server every tick to clients about everything on stage
					var i:int;
					serverTimeDiff = message.getInt(0);
					
					if(oldStateTime == 0)
					{
						oldStateTime = (new Date()).getTime()
						return;
					}
					//This is a very rudementry timestamp correction method
					//It is prone to error sometimes but is better then no correction.
					//Without correction, this line would be just "players[message.getInt(i*3 + 1)].x = message.getNumber(i*3 + 2)"
					for( i = 0;i<(message.length - 5)/2;i++){
						players[message.getInt(i*2 + 1)].x = message.getNumber(i*2 + 2) + 
														(players[message.getInt(i*2 + 1)].rightPressed ? (serverTimeDiff/2)* ( Math.abs(timeStateDiff - serverTimeDiff) / (1000/stage.frameRate) ) : 0) -
														(players[message.getInt(i*2 + 1)].leftPressed  ? (serverTimeDiff/2)* ( Math.abs(timeStateDiff - serverTimeDiff) / (1000/stage.frameRate) ) : 0);
						
					}
					i = i*2 +1;
					//Move ball with some prediction					
					ball.xVelocity = message.getNumber(i+2);
					ball.yVelocity = message.getNumber(i+3);
					//position_of_obj = pos_of_obj_from_server + Velocity_of_object * ping_time_in_frames
					ball.x = message.getNumber(i) + ball.xVelocity * ( Math.abs(timeStateDiff - serverTimeDiff) / (1000/stage.frameRate) );
					ball.y = message.getNumber(i+1) + ball.yVelocity * ( Math.abs(timeStateDiff - serverTimeDiff) / (1000/stage.frameRate) );
					
					//Take the weighted average of the expected message time and actual message time to get the old time
					//This average is useful for adapting to systematic variations to latency
					oldStateTime = ( (oldStateTime + message.getInt(0))*3 + (new Date()).getTime() )/4
					break;
				//Setting up info from server about events of all players into our array for further extrapolation
				case "leftUp":
					players[message.getInt(0)].leftPressed = false;
					break;					
				case "leftDown":
					players[message.getInt(0)].leftPressed = true;
					break;
				case "rightUp":
					players[message.getInt(0)].rightPressed = false;
					break;
				case "rightDown":
					players[message.getInt(0)].rightPressed = true;
					break;
				case "hitBall":
					hitSound.play();
					ball.xVelocity = message.getNumber(2);
					ball.yVelocity = message.getNumber(3);
					//position_of_obj = pos_of_obj_from_server + Velocity_of_object * ping_time_in_frames
					ball.x = message.getNumber(0);
					ball.y = message.getNumber(1);
					break;
			}
			trace("Recived the message", message)
		}
		
		//KeyDown event handler
		public function keyPressed(key:KeyboardEvent):void
		{			
			if (key.keyCode == 68||key.keyCode == 39 && !myBoard.rightPressed) 
			{
				connection.send("rightDown");
				myBoard.rightPressed = true;
			}
			if (key.keyCode == 65||key.keyCode == 37 && !myBoard.leftPressed) 
			{
				connection.send("leftDown");
				myBoard.leftPressed = true;
			}
		}
		
		//keyUp event handler
		public function keyReleased(key:KeyboardEvent):void
		{			
			if (key.keyCode == 68||key.keyCode == 39 && myBoard.rightPressed) 
			{
				connection.send("rightUp");
				myBoard.rightPressed = false;
			}
			if (key.keyCode == 65||key.keyCode == 37 && myBoard.leftPressed) 
			{
				connection.send("leftUp");
				myBoard.leftPressed = false;
			}
		}
		
		//Main game logic clientside
		public function everyFrame(event:Event):void
		{
			//trace(myBoard.pName);
			//compute the time since last fraame update
			var nowTime:Number = (new Date()).getTime();
			var timeFrameDiff:Number = nowTime - oldTime;
			oldTime = nowTime;
			//trace(serverTimeDiff);
			//Collision of ball with board, have to double-check on server after msg about collision received
			if( ball.hitTestObject( myBoard ) )
			{
				/*
				if ( myBoard.pName == 'First' )
				{
					ball.y = ball.y = myBoard.y - ball.height - myBoard.height / 2 ; 
				}
				else if ( myBoard.pName == 'Second' )
				{
					ball.y = ball.y = myBoard.y + myBoard.height + ball.height / 2 ;
				}*/
				//Switch ball direction and move it a bit in advance (again, prediction of server responce)
				//timeFrameDiff - serverTimeDiff is more of difference between framerate and tickrate than ping though
				ball.yVelocity *= -1*( Math.abs(timeFrameDiff - serverTimeDiff) / (1000/stage.frameRate) );
				ball.y += ball.yVelocity;
				//trace("That's a hit!");
				connection.send("hitBall");				
			}				
			
			//Move player objects based on their event values, sort of additional prediction for players, some extra smoothing
			for ( var player:String in players )
			{				
				if(players[player].rightPressed)
				{
					if( players[player].x >= stage.width - players[player].width )
						players[player].x = stage.width - players[player].width;
					else
						players[player].x += (serverTimeDiff/8) * ( Math.abs(timeFrameDiff - serverTimeDiff) / (1000/stage.frameRate) );
				}
				if(players[player].leftPressed)
				{
					if( players[player].x <= 0 )
						players[player].x = 0;
					else
						players[player].x -= (serverTimeDiff/8) * ( Math.abs(timeFrameDiff - serverTimeDiff) / (1000/stage.frameRate) );
				}
			}
		}
		
		private function handleDisconnect():void
		{
			trace("Disconnected from server")
		}
		
		private function handleError(error:PlayerIOError):void
		{
			trace("got",error)
			gotoAndStop(3);

		}
	}	
}
