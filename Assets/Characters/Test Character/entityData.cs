﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class entityData : MonoBehaviour {

    public GameObject tileOn;
    public int movementRange = 3;
    public int minAttackRange = 0;
    public int attackRange = 1;
    public int movementPoints;
    public int maxHealth = 12;
    public int currentHealth;
    public int maxSpells = 3;
    public int currentSpells;
    public GameObject healthBar;
    public GameObject healthImage;
    public DiceRoller diceRoller;
    public DiceRoller.DiceType attackDice;
    public int numDice;
    public int attackMod;
    public int armorClass;
	// Use this for initialization
	void Start () {
        movementPoints = movementRange;
        currentHealth = maxHealth;
        currentSpells = maxSpells;
	}

}
