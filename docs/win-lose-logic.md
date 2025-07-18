When the game starts, there is a global timer (We can start with 1 minute for testing purposes), but eventually I want to make it 10 minutes
When the timer ends, the game ends
Whether a player wins or loses depends on their stats.
If CCAT Score drops below 40 at any point before the timer ends, that player loses and should see a notification that says something like "You have been kicked out"
If Social Score is below 25 when the timer ends, that player loses and should see a notification that says something like "You did not get a job offer"
If Health drops to 0, the decay rate for Social and CCAT Score should decay 3 times as fast.  If Health is not 0, the decay rate for Social and CCAT Score should return to normal

If the timer ends and the player has 40+ CCAT Score and 25+ Social, the player wins and should see a notification that says "You got a $200k job"