//for ball movements, it's according coordinates will be updated by amount in this variables every frame
var xDirection:int;
var yDirection:int;

//score
var playerScore:Number;
var enemyScore:Number;

var winningScore:Number;

var hit:Sound = new Hit();


function initializeGame(event:MouseEvent):void
{
	playerScore = 0;
	enemyScore = 0;
	winningScore = 5;
	xDirection = 10;
    yDirection = -10;

	stage.frameRate = 60;
	
	//Hides score screen
	score_mc.gotoAndStop(1);	
	
	//Every frame fcns that process movement of all objects will be called
	stage.addEventListener( Event.ENTER_FRAME, renderAndProcess); 
	
	bg_mc.removeEventListener(MouseEvent.CLICK, initializeGame);	
	
	Mouse.hide();
}


function endGame()
{	
	//no longer call functions that are responsible for movements of objects in game
	stage.removeEventListener( Event.ENTER_FRAME, renderAndProcess);
	
	bg_mc.addEventListener(MouseEvent.CLICK, initializeGame); //Start game with mouse click
	
	Mouse.hide();
	
	//stop Engame screen (score screen) movieClip at last frame, so tha it shows score while game's paused
	score_mc.gotoAndStop(12); 
}

//Main function that will be called every frame
function renderAndProcess( event:Event )
{
	moveBall();
	movePaddle();
	moveEnemy();
}

//Displays score, as well as checks for endgame conditions
function showScore()
{
	if( playerScore >= winningScore)
	{
		score_mc.slide_mc.player_txt.text = "Player WINS!";
		score_mc.slide_mc.enemy_txt.text = "Click to play again";
		endGame();
	}
	else if( enemyScore >= winningScore)
	{
		score_mc.slide_mc.enemy_txt.text = "Enemy WINS!";
		score_mc.slide_mc.player_txt.text = "Click to play again";
		endGame();
	}
	else
	{
		score_mc.slide_mc.player_txt.text = "Player: " + playerScore;
		score_mc.slide_mc.enemy_txt.text = "Enemy: " + enemyScore;
		score_mc.gotoAndPlay(2);
	}	
}



//if walls behind enemy or player paddle were hit by ball
function resetBallPosition(starter:String )
{
	hit.play();
	if (starter == "player" )
	{
		xDirection = 10 * Math.pow( -1,(playerScore+enemyScore));
		yDirection = -10;
		ball_mc.x = paddle_mc.x + paddle_mc.width/2;
		ball_mc.y = paddle_mc.y - ball_mc.height - paddle_mc.height /2;
	}
	else if (starter == "enemy")
	{
		xDirection = 10 * Math.pow( -1,(playerScore+enemyScore));
		yDirection = 10;
		ball_mc.x = enemy_mc.x + enemy_mc.width/2;
		ball_mc.y = enemy_mc.y + ball_mc.height + enemy_mc.height /2;
	}

}

//Helper fcn to change x movement speed (and thus, angle) according to which part of paddle was hit
function checkHitLocation( paddle:MovieClip)
{
	var hitPercent:Number;
	var ballPosition:Number = ball_mc.x - paddle.x;
	hitPercent = (ballPosition / (paddle.width - ball_mc.width) ) -0.5;
	xDirection = hitPercent *40;
	yDirection *= 1.05;
}

//Bouncing and movement of ball
function moveBall()
{	
	// Against sidewalls
	if ( ball_mc.x <= 0)
	{
		xDirection *= -1;
		ball_mc.x = 0;
		hit.play();
	}
	else if( ball_mc.x >= stage.stageWidth - ball_mc.width)
	{
		xDirection *= -1;
		ball_mc.x = stage.stageWidth - ball_mc.width;
		hit.play();
	}
	
	//With player's paddle
	if( ball_mc.hitTestObject( paddle_mc ) )
	{
		yDirection *= -1;
		hit.play();
		//placing ball on top of player's paddle to avoid derping
		ball_mc.y = paddle_mc.y - ball_mc.height - paddle_mc.height /2; 
		checkHitLocation(paddle_mc);
	}
	
	//With enemy paddle
	if( ball_mc.hitTestObject( enemy_mc ) )
	{
		yDirection *= -1;
		hit.play();
		//placing ball below enemy's paddle to avoid derping
		ball_mc.y = enemy_mc.y + enemy_mc.height + ball_mc.height/2;
		checkHitLocation(enemy_mc);
	}
	
	//Against walls behind enemy and player paddles accordingly
	if ( ball_mc.y <= 0)
	{		
		playerScore++;
		showScore();
		resetBallPosition("player");
	}
	else if( ball_mc.y >= stage.stageHeight - ball_mc.height)
	{
		enemyScore++;
		showScore();
		resetBallPosition("enemy");
	}
	
	//movement of ball
	ball_mc.x += xDirection;
	ball_mc.y += yDirection;
}

//makes paddle move with mouse
function movePaddle()
{
	var targetX;
	//Constrains movement of paddle inside of window
	if( this.mouseX <= paddle_mc.width/2)
	{
		targetX = 0;
	}
	else if( this.mouseX >= stage.stageWidth - paddle_mc.width/2)
	{
		targetX = stage.stageWidth - paddle_mc.width;
	}
	else
	{
		targetX = this.mouseX - paddle_mc.width/2;
		//targetX = this.mouseX - paddle_mc.width/2;
		//paddle_mc.x += (targetX - paddle_mc.x) / easing;
	}	
	paddle_mc.x = targetX;
}

//"AI", movements of top board
function moveEnemy()
{
	var enemyTargetX:Number;
	//For paddle movement calculations
	var easing = Math.abs(yDirection)*0.6;
	enemyTargetX = ball_mc.x - enemy_mc.width/2;
	if( enemyTargetX <= 0 )
	{
		enemyTargetX = 0;
	}
	else if( enemyTargetX >= stage.stageWidth - enemy_mc.width )
	{
		enemyTargetX = stage.stageWidth - enemy_mc.width;
	}
	enemy_mc.x += ( enemyTargetX - enemy_mc.x ) / easing;
}

//As soon as mouse is clicked, initializeGame() will be called
bg_mc.addEventListener(MouseEvent.CLICK, initializeGame);