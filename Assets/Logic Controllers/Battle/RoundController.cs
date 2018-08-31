using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RoundController : MonoBehaviour {

    public Queue<GameObject> characters;
    public bool roundOver = false;
    public bool victory = false;
    public enum roundStateEnum {CharacterSelect, CharacterTurn, CharacterEnd};
    public roundStateEnum roundState = roundStateEnum.CharacterSelect;
    GameObject currentPlayer;
    public void StartUp(GameObject[] players, GameObject[] enemies) {
        foreach (GameObject x in players)
        {
            characters.Enqueue(x);
        }
        foreach (GameObject x in enemies)
        {
            characters.Enqueue(x);
        }
    }

	void Update () {
        /*
		if (!roundOver)
        {
            switch (roundState)
            {
                case roundStateEnum.CharacterSelect:
                    currentPlayer = characters.Dequeue();
                    roundState = roundStateEnum.CharacterTurn;
                    break;
                case roundStateEnum.CharacterTurn:

                    break;
                case roundStateEnum.CharacterEnd:
                    roundState = roundStateEnum.CharacterSelect;
                    characters.Enqueue(currentPlayer);
                    break;
            }
        } else
        {

        }
        */
	}
}
