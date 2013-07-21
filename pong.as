//for ball movements
var xDirection:int = 10;
var yDirection:int = -10;

//For paddle movement calculations
var targetX:int = paddle_mc.x;
var easing = 7;

//score
var playerScore:Number;
var enemyScore:Number;

var winningScore:Number = 3;

var hit:Sound = new Hit();

function initializeGame(event:MouseEvent):void
{
	playerScore = 0;
	enemyScore = 0;
	
	score_mc.gotoAndStop(1);
	
	//ball staarts noving after mouseclick
	ball_mc.addEventListener( Event.ENTER_FRAME, moveBall);
	//paddle movement with mouse
	paddle_mc.addEventListener( Event.ENTER_FRAME, movePaddle);
	//no longer need event listener
	bg_mc.removeEventListener(MouseEvent.CLICK, initializeGame);
	//for enemy
	enemy_mc.addEventListener(Event.ENTER_FRAME, moveEnemy);
	
	Mouse.hide();
}

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

function endGame()
{
	//ball staarts noving after mouseclick
	ball_mc.removeEventListener( Event.ENTER_FRAME, moveBall);
	//paddle movement with mouse
	paddle_mc.removeEventListener( Event.ENTER_FRAME, movePaddle);
	//no longer need event listener
	bg_mc.addEventListener(MouseEvent.CLICK, initializeGame);
	//for enemy
	enemy_mc.removeEventListener(Event.ENTER_FRAME, moveEnemy);
	Mouse.hide();
	
	score_mc.gotoAndStop(12);
}

//if walls behind enemy or player paddle was hit
function resetBallPosition()
{
	hit.play();
	xDirection = 10;
	yDirection = -10;
	ball_mc.x = paddle_mc.x + paddle_mc.width/2;
	ball_mc.y = paddle_mc.y - ball_mc.height - paddle_mc.height /2;

}

//to change x movement speed according to which part of paddle was hit
function checkHitLocation( paddle:MovieClip)
{
	var hitPercent:Number;
	var ballPosition:Number = ball_mc.x - paddle.x;
	hitPercent = (ballPosition / (paddle.width - ball_mc.width) ) -0.5;
	xDirection = hitPercent *40;
	yDirection *= 1.05;
}

//bouncing and movement of ball
function moveBall( event:Event)
{	
	// Against sidewalls
	if ( ball_mc.x <= 0)
	{
		xDirection *= -1;
		hit.play();
	}
	else if( ball_mc.x >= stage.stageWidth - ball_mc.width)
	{
		xDirection *= -1;
		hit.play();
	}
	
	//With player's paddle
	if( ball_mc.hitTestObject( paddle_mc ) )
	{
		yDirection *= -1;
		hit.play();
		ball_mc.y = paddle_mc.y - ball_mc.height - paddle_mc.height /2;
		checkHitLocation(paddle_mc);
	}
	
	//With enemy paddle
	if( ball_mc.hitTestObject( enemy_mc ) )
	{
		yDirection *= -1;
		hit.play();
		ball_mc.y = enemy_mc.y + enemy_mc.height + ball_mc.height/2;
		checkHitLocation(enemy_mc);
	}
	
	//Against walls behind enemy and player paddles accordingly
	if ( ball_mc.y <= 0)
	{		
		playerScore++;
		showScore();
		resetBallPosition();
	}
	else if( ball_mc.y >= stage.stageHeight - ball_mc.height)
	{
		enemyScore++;
		showScore();
		resetBallPosition();
	}
	
	//movement of ball
	ball_mc.x += xDirection;
	ball_mc.y += yDirection;
}

//makes paddle move with mouse
function movePaddle(event:Event)
{
	/*if( this.mouseX <= paddle_mc.width/2)
	{
		targetX = 0;
	}
	else if( this.mouseX >= stage.stageWidth - paddle_mc.width/2)
	{
		targetX = stage.stageWidth - paddle_mc.widht;
	}
	else
	{*/
		targetX = this.mouseX - paddle_mc.width/2;
		paddle_mc.x += (targetX - paddle_mc.x) / easing;
	/*}*/	
}

//"AI"
function moveEnemy(event:Event)
{
	var enemyTargetX:Number;
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

bg_mc.addEventListener(MouseEvent.CLICK, initializeGame);