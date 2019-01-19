using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DiceRoller {

    public enum DiceType {Hundred, Twenty, Twelve, Ten, Eight, Six, Four};
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

    public int diceRoll(DiceType dice)
    {
        switch (dice)
        {
            case DiceType.Hundred:
                return HundredDice();
            case DiceType.Twenty:
                return TwentyDice();
            case DiceType.Twelve:
                return TwelveDice();
            case DiceType.Ten:
                return TenDice();
            case DiceType.Eight:
                return EightDice();
            case DiceType.Six:
                return SixDice();
            case DiceType.Four:
                return FourDice();
        }
        return 0;
    }
}
