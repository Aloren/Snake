#include <LiquidCrystal.h>

int keybPin = 5;
int unusedPin = 4;
int musicPin = 3;

int delayTime = 120;
int keyFreq = 20;
const int startCol = 0, startRow = 7;
const int startLength = 3;
int length = startLength;

int x, y;
int headCol, headRow;
int foodCol, foodRow;
int poisonCol, poisonRow;
const int startDirection = 3;
int direction = startDirection; //0 - left; 1 - down; 2 - up 3 - right

int number = 1;
boolean runGame = true;

LiquidCrystal lcd(10,11,12,13,14,15,16);

int timerFood = 0;
int timerPoison = 0;
const int timerStop = 100;
const byte food = 120;
const byte poison = 130;

byte nullChar[8] = {
  B00000,
  B00000,
  B00000,
  B00000,
  B00000,
  B00000,
  B00000,
  B00000};
  
byte newChar[8];

const int rows = 16;
const int cols = 80;
byte matrix[rows][cols];

void setup() {
  Serial.begin(9600);
  lcd.createChar(0, nullChar);
  lcd.begin(16, 2);
  lcd.setCursor(0, 1);
  lcd.print("SNAKE v.0.1");  
  delay(200);
  lcd.clear();
  initSnake();
  randomSeed(analogRead(unusedPin)); //from unused analog pin
}

void loop() {
  int button = keyScan(); 
  if(runGame) {
    outputGame();
    timerFood++;
    timerPoison++;    
    makeNewFood();  
    makeNewPoison();
    playGame(button); 
    delay(delayTime);
  } else{
    gameOver(button);
  }
}

void playGame(int button) {
  switch(button) {
  case 1: {
      Serial.println("Left button pressed");
      if(direction != 3) {//if not moving right
        direction = 0; 
        moveSnakeLeft();
      } else moveSnakeDirection();
      break;
  }
  case 2: {
      Serial.println("Up button pressed");
      if(direction != 1) {//if not moving down
        direction = 2; 
        moveSnakeUp();
      } else moveSnakeDirection();
      break;
  }
  case 3: { 
      Serial.println("Down button pressed");
      if(direction != 2) {
        direction = 1; 
        moveSnakeDown(); 
      } else moveSnakeDirection();
      break;
  }
  case 4: {
      Serial.println("Right button pressed");
      if(direction != 0) {
        direction = 3; 
        moveSnakeRight();
      } else moveSnakeDirection();
      break;
  }
  default: moveSnakeDirection();
  } //end switch(button)
}

void moveSnakeDirection() {
  switch(direction) {
    case 0: moveSnakeLeft(); break;
    case 1: moveSnakeDown(); break;  
    case 2: moveSnakeUp(); break;
    case 3: moveSnakeRight(); break;
    default: moveSnakeRight();
  }
}

void outputGame() {
  byte nulls = 0;    
  for (int i = 0; i < 16; i++) { //by cols (16 chars per line)
    for (int j = 0; j < 8; j++) { //by rows  (8 rows in line)  
      newChar[j] = convertIntsToByte(j,i);
      if (newChar[j] == 0) {
        nulls++;
      }
    }
    writeCharacter(i, 0, nulls);
    nulls = 0;
  }
  //second line
  lcd.setCursor(0,1);
  for (int i = 0; i < 16; i++) { //by cols
    for (int j = 8, k = 0; j < 16; j++, k++) { //by rows
      newChar[k] = convertIntsToByte(j,i);
      if (newChar[k] == 0) {
        nulls++;
      }
    }
    writeCharacter(i, 1, nulls);
    nulls = 0;
  }
  lcd.setCursor(0,0);
}

void writeCharacter(int col, int row, byte nulls) {
  if (nulls == 8) {
    lcd.write(0);
  } else {
    lcd.createChar(number,newChar);
    lcd.setCursor(col,row);
    lcd.write(number);
    incNumber();
  }
}

void moveSnakeRight() {
  moveSnake();
  headCol++;
  checkSetHeadCol();
  tryEatFood(); 
}

void moveSnakeLeft() {
  moveSnake();
  headCol--;
  checkSetHeadCol();
  tryEatFood(); 
}

void moveSnakeDown() {
  moveSnake();
  headRow++;
  checkSetHeadRow();
  tryEatFood(); 
}

void moveSnakeUp() {
  moveSnake();
  headRow--;
  checkSetHeadRow();
  tryEatFood();  
}

void moveSnake() {
  for (int i = 0; i < rows; i++) { //by rows
    for (int j = 0; j < cols; j++) { //by cols
      if(matrix[i][j] != 0 && matrix[i][j] != food)
        matrix[i][j]--;
    }
  }
}

void tryEatFood() {
  if(headCol == foodCol && headRow == foodRow) {
    matrix[headRow][headCol] = length;
    incrementLength();
    timerFood = 0;
    putFood();
  }
  matrix[headRow][headCol] = length;  
}

void checkSetHeadCol() {
  if(headCol == 80) {
    headCol = 0;
  }
  if(headCol == -1) {
    headCol = 79;
  }
  checkGameOver();
}
void checkSetHeadRow() {
  if(headRow == 16) {
    headRow = 0;
  }
  if(headRow == -1) {
    headRow = 15;
  }
  checkGameOver();
}

void checkGameOver() {  
  //Serial.print("Check game over matrix[");Serial.print(headRow);Serial.print("][");Serial.print(headCol);Serial.print("]="); 
  //Serial.println(matrix[headRow][headCol], DEC); 
  if (((headRow == poisonRow) && (headCol == poisonCol))
  ||((headRow == poisonRow + 1) && (headCol == poisonCol + 1))) {
    runGame = false;
    resetMatrix();
  }
  if (matrix[headRow][headCol] != 0 && matrix[headRow][headCol] != food) {    
    runGame = false;
    resetMatrix();
  }
}

void incrementLength() {
  length++;
  if (direction == 3) {//moving right
    headCol++;  
    checkSetHeadCol();  
  } else if(direction == 0) { //left
    headCol--;
    checkSetHeadCol();    
  } else if(direction == 1) { //down
    headRow++;
    checkSetHeadRow();
  } else if(direction == 2) { //up
    headRow--;
    checkSetHeadRow();
  }
}

void makeNewFood() {
 if(timerFood == timerStop) {
   matrix[foodRow][foodCol] = 0;
   putFood();
   timerFood = 0;
 }
}

void makeNewPoison() {
 if(timerPoison == timerStop) {
   matrix[poisonRow][poisonCol] = 0;
   matrix[poisonRow + 1][poisonCol + 1] = 0;
   putPoison();
   timerPoison = 0;
 }  
}

void initSnake() {
  headCol = startCol + length - 1;
  headRow = startRow;
  for(int i = startCol, j = 1; i <= headCol; i++, j++){
    matrix[startRow][i] = j;
  }
  putFood();
  putPoison();
}

void putFood() {
  do {
    foodCol = random(0, cols);
    foodRow = random(0, rows);
  } while(matrix[foodRow][foodCol] != 0);
  matrix[foodRow][foodCol] = food;
}

void putPoison() {
  do {
    poisonCol = random(0, cols - 1);
    poisonRow = random(0, rows - 1);
  } while(matrix[poisonRow][poisonCol] != 0 && matrix[poisonRow + 1][poisonCol + 1] != 0);
  matrix[poisonRow][poisonCol] = poison;
  matrix[poisonRow + 1][poisonCol + 1] = poison;
}

void gameOver(int button) {
  lcd.clear();
  lcd.print("Game over");
  delay(delayTime);
  if(button == 1) {
    newGame();
  }
}

void newGame() {
  lcd.clear();
  timerFood = 0;
  timerPoison = 0;
  length = startLength;
  direction = startDirection;
  resetMatrix();
  initSnake();  
  runGame = true;
}

void resetMatrix() {
  for (int i = 0; i < rows; i++) { //by rows
    for (int j = 0; j < cols; j++) { //by cols
        matrix[i][j] = 0;
    }
  }
}

byte convertIntsToByte(int row, int col) {
  byte charI = 0;
  col = col*5;
  for (int i = col, j = 4; i < col + 5; i++, j--) {
    if (matrix[row][i] != 0) {
      charI |= (1 << j);
    }
  }
  return charI;
}

int keyScan() {
  int value = analogRead(keybPin);
  if (value >= 610 && value <= 620) {
    return 1;
  } else if (value >= 555 && value <= 565) {
    return 2;
  } else if (value >= 510 && value <= 520) {
    return 3;
  } else if (value >= 470 && value <= 480) {
    return 4;
  } else if (value >= 360 && value <= 370) {
    return 5;
  } else if (value >= 380 && value <= 390) {
    return 6;
  } else if (value >= 405 && value <= 415) {
    return 7;
  } else if (value >= 435 && value <= 445) {
    return 8;
  } else {
    return -1;
  }
}

void incCursor() {
  x++;
  if(x == 16) {
    x = 0;
    y++; 
    if(y == 2) {
      y = 0;   
    }    
  }
}

void incNumber() {
  number++;
  if(number == 8) {
    number = 1;
  }
}

void outFood() {
  Serial.print("FoodCol="); Serial.print(foodCol);
  Serial.print("FoodRow="); Serial.println(foodRow);
  Serial.println();
}

void outM() {
  for (int i = 0; i < rows; i++) { //by rows
    for (int j = 0; j < cols; j++) { //by cols
      Serial.print(matrix[i][j], DEC); 
      Serial.print(" ");
    }
    Serial.println();
  }  
}



























