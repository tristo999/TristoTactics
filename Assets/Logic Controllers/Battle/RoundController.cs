using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RoundController : MonoBehaviour {

    public Queue<GameObject> characters;
    public Map gameMap;
    public bool roundOver = false;
    public bool victory = false;
    public enum roundStateEnum {CharacterSelect, CharacterTurn, CharacterEnd, Movement, SpecialEvent, EnemyMovement, EnemyPause};
    public roundStateEnum roundState = roundStateEnum.CharacterSelect;
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
                            roundState = roundStateEnum.CharacterTurn;
                            gameMap.initialPlayerTurn(currentPlayer);
                            mainCamera.GetComponent<CameraMovementBattle>().moveCamera(currentPlayer.transform.position);
                            break;
                        case roundStateEnum.CharacterTurn:
                            if (currentPlayer.tag == "Player")
                            {
                                roundState = gameMap.playerTurn(currentPlayer);

                            }
                            else
                            {
                                Debug.Log("Enemy Turn");
                                roundState = roundStateEnum.EnemyPause;
                                timer = 0;
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
                            Debug.Log("Waiting!");
                            if (timer > enemyPauseTime)
                            {
                                roundState = gameMap.enemyTurn(currentPlayer);
                            }
                            else
                            {
                                timer += Time.deltaTime;
                            }
                            break;
                        case roundStateEnum.CharacterEnd:
                            gameMap.resetMap();
                            roundState = roundStateEnum.CharacterSelect;
                            characters.Enqueue(currentPlayer);
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
}
