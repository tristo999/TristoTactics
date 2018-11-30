using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DiceRoller : MonoBehaviour {

    public int HundredDice()
    {
        return Random.Range(1,101);
    }
    public int TwentyDice()
    {
        return Random.Range(1, 21);
    }
    public int TwelveDice()
    {
        return Random.Range(1, 13);
    }
    public int TenDice()
    {
        return Random.Range(1, 11);
    }
    public int EightDice()
    {
        return Random.Range(1, 9);
    }
    public int SixDice()
    {
        return Random.Range(1, 7);
    }
    public int FourDice()
    {
        return Random.Range(1, 5);
    }
}
