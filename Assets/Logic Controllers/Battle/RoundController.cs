using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RoundController : MonoBehaviour {

    public Queue<GameObject> characters;
    public Map gameMap;
    public bool roundOver = false;
    public bool victory = false;
    public enum roundStateEnum {CharacterSelect, CharacterTurn, CharacterEnd};
    public roundStateEnum roundState = roundStateEnum.CharacterSelect;
    GameObject currentPlayer;
    public bool roundStart = false;
    public bool turnOver = false;
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
    }

	void Update () {
        if (roundStart)
        {
            if (!roundOver)
            {
                switch (roundState)
                {
                    case roundStateEnum.CharacterSelect:
                        currentPlayer = characters.Dequeue();
                        roundState = roundStateEnum.CharacterTurn;
                        turnOver = false;
                        break;
                    case roundStateEnum.CharacterTurn: 
                        if (currentPlayer.tag == "Player")
                        {
                            turnOver = gameMap.playerTurn(currentPlayer);
                        } else
                        {

                        }
                        if (turnOver)
                        {
                            roundState = roundStateEnum.CharacterEnd;
                        }
                        break;
                    case roundStateEnum.CharacterEnd:
                         
                        roundState = roundStateEnum.CharacterSelect;
                        characters.Enqueue(currentPlayer);
                        break;
                }
            }
            else
            {
  
            }
        }
	}
}
