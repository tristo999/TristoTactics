using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RoundController : MonoBehaviour {

    public Queue<GameObject> characters;
    public Map gameMap;
    public bool roundOver = false;
    public bool victory = false;
    public enum roundStateEnum {CharacterSelect, CharacterTurn, CharacterEnd, Movement,SpecialEvent, EnemyTurn};
    public roundStateEnum roundState = roundStateEnum.CharacterSelect;
    GameObject currentPlayer;
    public bool roundStart = false;
    public bool gamePause;
    public void Start()
    {
        gameMap = gameObject.GetComponent<Map>();
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
                        break;
                    case roundStateEnum.CharacterTurn: 
                        if (currentPlayer.tag == "Player")
                        {
                            roundState = gameMap.playerTurn(currentPlayer);

                        } else
                        {
                            roundState = gameMap.enemyTurn(currentPlayer);
                        }
                        break;
                    case roundStateEnum.Movement:
                        roundState = gameMap.moveAlongPath(currentPlayer);
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
  
            }
        }
	}
}
