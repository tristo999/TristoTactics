using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RoundController : MonoBehaviour {

    public Queue<GameObject> characters;
    public Map gameMap;
    public bool roundOver = false;
    public bool victory = false;
    public enum roundStateEnum {CharacterSelect, CharacterTurn, CharacterEnd, Movement, SpecialEvent, EnemyMovement, EnemyPause};
    public enum playerStates {playerMove, playerAttack, playerMagic, playerInventory, playerInteract, playerBase};
    public roundStateEnum roundState = roundStateEnum.CharacterSelect;
    public roundStateEnum prevState;
    public playerStates playerRound = playerStates.playerBase;
    public GameObject currentPlayer;
    public bool roundStart = false;
    public bool gamePause;
    public float enemyPauseTime = 5f;
    public float timer;
    GameObject mainCamera;
    public void Start()
    {
        gameMap = gameObject.GetComponent<Map>();
        mainCamera = GameObject.FindGameObjectWithTag("MainCamera");

    }
    public void StartUp(GameObject[] players, GameObject[] enemies) {
        characters = new Queue<GameObject>();
        foreach (GameObject x in players)
        {
            characters.Enqueue(x);
        }
        foreach (GameObject x in enemies)
        {
            characters.Enqueue(x);
        }
        roundStart = true;
        gameMap.setUpMap();
        gameMap.setUpHealthUI();

    }

	void FixedUpdate () {
        if (!gamePause) {
            if (roundStart)
            {
                if (!roundOver)
                {
                    switch (roundState)
                    {
                        case roundStateEnum.CharacterSelect:
                            currentPlayer = characters.Dequeue();
                            if (currentPlayer.activeInHierarchy)
                            {
                                roundState = roundStateEnum.CharacterTurn;
                                if (currentPlayer.tag == "Player")
                                {
                                    gameMap.initialPlayerTurn(currentPlayer);
                                    playerRound = playerStates.playerBase;
                                }
                                else
                                {
                                    gameMap.initialEnemyTurn(currentPlayer);
                                }
                                mainCamera.GetComponent<CameraMovementBattle>().moveCamera(currentPlayer.transform.position);
                            } else
                            {
                                roundState = roundStateEnum.CharacterEnd;
                            }
                            break;
                        case roundStateEnum.CharacterTurn:
                            if (currentPlayer.tag == "Player")
                            {
                                switch (playerRound)
                                {

                                    case playerStates.playerBase:
                                        roundState = gameMap.playerTurn(currentPlayer);
                                        break;
                                    case playerStates.playerMove:
                                        roundState = gameMap.playerTurnMove(currentPlayer);
                                        break;
                                    case playerStates.playerAttack:
                                        roundState = gameMap.playerTurnAttack(currentPlayer);
                                        break;
                                }

                            }
                            else
                            {
                                roundState = gameMap.enemyTurn(currentPlayer);
                            }
                            break;
                        case roundStateEnum.Movement:
                            roundState = gameMap.moveAlongPath(currentPlayer);
                            mainCamera.GetComponent<CameraMovementBattle>().moveCamera(currentPlayer.transform.position);
                            break;
                        case roundStateEnum.EnemyMovement:
                            roundState = gameMap.moveAlongPath(currentPlayer);
                            mainCamera.GetComponent<CameraMovementBattle>().moveCamera(currentPlayer.transform.position);
                            break;
                        case roundStateEnum.EnemyPause:
                            if (timer > enemyPauseTime)
                            {
                                roundState = prevState;
                            }
                            else
                            {
                                timer += Time.deltaTime;
                                mainCamera.GetComponent<CameraMovementBattle>().moveCamera(currentPlayer.transform.position);
                            }
                            break;
                        case roundStateEnum.CharacterEnd:
                            gameMap.resetMap();
                            roundState = roundStateEnum.CharacterSelect;
                            characters.Enqueue(currentPlayer);
                            bool playersAlive = gameMap.checkPlayers();
                            bool enemiesAlive = gameMap.checkEnemies();
                            if (!playersAlive || !enemiesAlive)
                            {
                                roundOver = true;
                            }
                            break;
                        case roundStateEnum.SpecialEvent:
                            break;
                    }
                }
                else
                {
                    //Round Over
                    Application.Quit();
                }
            }
        }
	}

    public   void enemyWait(roundStateEnum nextState)
    {
        prevState = nextState;
        timer = 0;
    }
}
