using System.Collections;
using System.Collections.Generic;
using UnityEngine.UI;
using UnityEngine;

public class Map : MonoBehaviour {

    public float characterSpeed = 100000000;
    public GameObject[] tileMap;
    public GameObject[] players;
    public GameObject[] enemies;
    public GameObject masterGameObject;
    public RoundController roundController;
    public GameObject tileClicked;
    public bool selectedTile = false;
    public Queue<GameObject> shortestPath;
    public bool pathFound = false;
    public bool moved = false;
    public bool movingNow = false;
    public bool action = false;
    public bool turnEnd = false;
    public bool moving = false;
    public bool inEnemyRange = false;
    public GameObject movingToward;
    public int maxRange = 60;
    public entityData currentPlayerData;
    public List<GameObject> entitiesInRange;
    public bool initialRun;
    public GameObject currentPlayer;
    public GameObject playerUI;
    public GameObject[] healthBars;
    public GameObject healthUIPanel;
    public GameObject[] healthImages;
    public DiceRoller dice;

    // Use this for initialization
    void Start ()
    {
        tileMap = GameObject.FindGameObjectsWithTag("Environment");
        players = GameObject.FindGameObjectsWithTag("Player");
        enemies = GameObject.FindGameObjectsWithTag("Enemy");
        findTileOn();
        roundController = masterGameObject.GetComponent<RoundController>();
        roundController.StartUp(players, enemies);
        shortestPath = new Queue<GameObject>();
        entitiesInRange = new List<GameObject>();
        playerUI = GameObject.FindGameObjectWithTag("PlayerUI");
        playerUI.SetActive(false);
        healthUIPanel = GameObject.FindGameObjectWithTag("HealthUIPanel");
        dice = new DiceRoller();
	}
	

    void FindRange(GameObject player)
    {
        entityData data = player.GetComponent<entityData>();
        rangebfs(currentPlayerData.movementPoints,data.tileOn);
        inEnemyRange = false;
    }

    void FindRangeAttack(GameObject player)
    {
        entityData data = player.GetComponent<entityData>();
        if (currentPlayerData.attackRange == 1)
        {
            rangebfsAttackM(currentPlayerData.minAttackRange, currentPlayerData.attackRange, data.tileOn);
        }
        else
        {
            rangebfsAttack(currentPlayerData.minAttackRange, currentPlayerData.attackRange, data.tileOn);
        }
        inEnemyRange = false;
    }

    // LOOPS THROUGH EVERY POSSIBLE PATH 1-RANGE LENGTH -- TOO EXPENSIVE TO WORK
    void rangebfs(int range, GameObject tile)
    {
        if (range != 0)
        {
            TileData tileDataX = tile.GetComponent<TileData>();
            foreach (GameObject y in tileDataX.neighbors)
            {
                    TileData tileData = y.GetComponent<TileData>();
                    if (tileData.passable && tileData.entityOn == null)
                    {
                        rangebfs(range - 1, y);
                        SpriteRenderer rend = y.GetComponent<SpriteRenderer>();
                        rend.material.color = Color.gray;
                        tileData.inRange = true;
                           
                    } 
            }
        }
    }

    void rangebfsAttackM(int innerRange, int outerRange, GameObject tile)
    {
        foreach (GameObject y in tileMap)
        {
            if (Vector3.Distance(tile.transform.position, y.transform.position) < 1.5f) {
                TileData tileData = y.GetComponent<TileData>();
                SpriteRenderer rend = y.GetComponent<SpriteRenderer>();
                rend.material.color = Color.red;
                tileData.inAttackRange = true;
            }
        }
    }
    void rangebfsAttack(int innerRange, int outerRange, GameObject tile)
    {
        if (outerRange != 0)
        {
            TileData tileDataX = tile.GetComponent<TileData>();
            foreach (GameObject y in tileDataX.neighbors)
            {
                TileData tileData = y.GetComponent<TileData>();
                    rangebfsAttack(innerRange - 1, outerRange - 1, y);
                    if (innerRange <= 0)
                    {
                        SpriteRenderer rend = y.GetComponent<SpriteRenderer>();
                        rend.material.color = Color.red;
                        tileData.inAttackRange = true;
                        if (tileData.entityOn != null)
                    {
                        entitiesInRange.Add(tileData.entityOn);
                    }
                    }
            }
        }
    }




    public void initialPlayerTurn(GameObject player)
    {
        findTileOn();
        currentPlayerData = player.GetComponent<entityData>();
        currentPlayerData.movementPoints = currentPlayerData.movementRange;
        currentPlayer = player;
        playerUI.SetActive(true);
        action = false;
    }
    public void initialEnemyTurn(GameObject player)
    {
        findTileOn();
        currentPlayerData = player.GetComponent<entityData>();
        currentPlayerData.movementPoints = currentPlayerData.movementRange;
        FindRange(player);
        initialRun = false;
    }
    
    public RoundController.roundStateEnum playerTurn(GameObject player)
    {
        return RoundController.roundStateEnum.CharacterTurn;
    }

    public void changePlayerMove()
    {
        if (currentPlayer.GetComponent<entityData>().movementPoints != 0)
        {
            FindRange(currentPlayer);
            roundController.playerRound = RoundController.playerStates.playerMove;
            playerUI.SetActive(false);
        }
    }

    public void changePlayerAttack()
    {
        if (!action)
        {
            FindRangeAttack(currentPlayer);
            roundController.playerRound = RoundController.playerStates.playerAttack;
            playerUI.SetActive(false);
        }
    }

    public void playerEndTurn()
    {
        playerUI.SetActive(false);
        roundController.roundState = RoundController.roundStateEnum.CharacterEnd;
    }

    public RoundController.roundStateEnum playerTurnMove(GameObject player)
    {
        if (currentPlayerData.movementPoints != 0)
        {
            if (selectedTile)
            {
                moveCharacter(player, tileClicked);
                movingNow = true;
            }
        }
        if (movingNow)
        {
            return RoundController.roundStateEnum.Movement;
        }
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            resetMap();
            roundController.playerRound = RoundController.playerStates.playerBase;
            playerUI.SetActive(true);
        }
        return RoundController.roundStateEnum.CharacterTurn;
    }

    public RoundController.roundStateEnum playerTurnAttack(GameObject player)
    {
        action = true;
        if (selectedTile)
        {
            GameObject enemy = tileClicked.GetComponent<TileData>().entityOn;
            entityData playerData = player.GetComponent<entityData>();
            entityData enemyData= enemy.GetComponent<entityData>();
            if (dice.TwentyDice() + playerData.attackMod >= enemyData.armorClass)
            {
                //Hit
                Debug.Log("Hit!");
                Debug.Log("Current Enemy Health : " + enemyData.currentHealth);
                for (int i = 0; i < playerData.numDice; i++)
                {
                    enemyData.currentHealth -= dice.diceRoll(playerData.attackDice);
                }
                enemyData.currentHealth -= playerData.attackMod;
                Debug.Log("New Enemy Health : " + enemyData.currentHealth);
            } else
            {
                //Miss
                Debug.Log("Miss");
            }
            if (enemyData.currentHealth <= 0)
            {
                enemy.SetActive(false);
                
            }
            resetMap();
            roundController.playerRound = RoundController.playerStates.playerBase;
            playerUI.SetActive(true);
            resolveHealthUI();
        }
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            resetMap();
            roundController.playerRound = RoundController.playerStates.playerBase;
            playerUI.SetActive(true);
        }
        return RoundController.roundStateEnum.CharacterTurn;
    }

    public RoundController.roundStateEnum enemyTurn(GameObject player)
    {
        if (!initialRun)
        {
            FindRange(player);
            roundController.enemyWait(RoundController.roundStateEnum.CharacterTurn);
            initialRun = true;
            return RoundController.roundStateEnum.EnemyPause;
        }
        else
        {
            bool inRange = EnemyInRange(player);
            if (inRange)
            {
                if (action)
                {
                    return RoundController.roundStateEnum.CharacterEnd;
                }
                else
                {
                    //Do Action
                    Debug.Log("Attack!");
                    GameObject attackedPlayer = players[0];
                    foreach(GameObject x in players)
                    {
                        if (Vector3.Distance(x.transform.position, player.transform.position) < 1.5f && x.activeInHierarchy)
                        {
                            attackedPlayer = x;
                        }
                    }
                    entityData playerData = player.GetComponent<entityData>();
                    entityData enemyData = attackedPlayer.GetComponent<entityData>();
                    if (dice.TwentyDice() + playerData.attackMod >= enemyData.armorClass)
                    {
                        //Hit
                        Debug.Log("Hit!");
                        Debug.Log("Current Enemy Health : " + enemyData.currentHealth);
                        for (int i = 0; i < playerData.numDice; i++)
                        {
                            enemyData.currentHealth -= dice.diceRoll(playerData.attackDice);
                        }
                        enemyData.currentHealth -= playerData.attackMod;
                        Debug.Log("New Enemy Health : " + enemyData.currentHealth);
                    }
                    else
                    {
                        //Miss
                        Debug.Log("Miss");
                    }
                    if (enemyData.currentHealth <= 0)
                    {
                        attackedPlayer.SetActive(false);

                    }
                    resetMap();
                    resolveHealthUI();
                    return RoundController.roundStateEnum.CharacterEnd;
                }
            }
            else
            {
                if (!moved)
                {
                    Debug.Log("Moving Enemy");
                    GameObject closestPlayer = GameObject.FindGameObjectWithTag("Player");
                    foreach (GameObject x in players)
                    {
                        if (Vector3.Distance(x.transform.position, player.transform.position) < Vector3.Distance(player.transform.position, closestPlayer.transform.position) && x.activeInHierarchy)
                        {
                            closestPlayer = x;
                        }
                    }
                    shortestPath = new Queue<GameObject>();
                    // Find shortest path to inrange tile
                    /*
                    moveCharacter(player, closestPlayer.GetComponent<entityData>().tileOn.GetComponent<TileData>().tileWest.GetComponent<TileData>().tileNorth);
                    moveCharacter(player, closestPlayer.GetComponent<entityData>().tileOn.GetComponent<TileData>().tileWest);
                    moveCharacter(player, closestPlayer.GetComponent<entityData>().tileOn.GetComponent<TileData>().tileWest.GetComponent<TileData>().tileSouth);
                    moveCharacter(player, closestPlayer.GetComponent<entityData>().tileOn.GetComponent<TileData>().tileNorth);
                    moveCharacter(player, closestPlayer.GetComponent<entityData>().tileOn.GetComponent<TileData>().tileEast.GetComponent<TileData>().tileNorth);
                    moveCharacter(player, closestPlayer.GetComponent<entityData>().tileOn.GetComponent<TileData>().tileEast);
                    moveCharacter(player, closestPlayer.GetComponent<entityData>().tileOn.GetComponent<TileData>().tileEast.GetComponent<TileData>().tileSouth);
                    moveCharacter(player, closestPlayer.GetComponent<entityData>().tileOn.GetComponent<TileData>().tileSouth);
                    */
                    moveCharacter(player, closestPlayer.GetComponent<entityData>().tileOn);
                    return RoundController.roundStateEnum.EnemyMovement;

                }
                else
                {

                    return RoundController.roundStateEnum.CharacterEnd;

                }
            }
        }
         
    }
    public void selectTile(GameObject tileClicked)
    {
        selectedTile = true;
        this.tileClicked = tileClicked; 
    }
    public void findShortestPath(Dictionary<GameObject, int> distances, Dictionary<GameObject, bool> visited, Dictionary<GameObject, GameObject> parents, GameObject source, GameObject destination)
    {
        if (source.transform.position != destination.transform.position)
        {
            TileData tileDataSource = source.GetComponent<TileData>();
            foreach (GameObject x in tileDataSource.neighbors)
            {
                if(!visited[x] && (x.GetComponent<TileData>().entityOn == null || x == destination) && x.GetComponent<TileData>().passable)
                {
                    if ((distances[source] + 1) < distances[x])
                    {
                        distances[x] = distances[source] + 1;
                        parents[x] = source;
                    }
                }
            }
            int min = int.MaxValue;
            GameObject minGameObject = source;
            foreach (KeyValuePair<GameObject, int> x in distances)
            {   
                if (x.Value < min && !visited[x.Key])
                {
                    min = x.Value;
                    minGameObject = x.Key;
                }
            }
            visited[minGameObject] = true;
            findShortestPath(distances, visited, parents, minGameObject, destination);
        } else {
            distances[destination] = distances[source];
            pathFound = true;
            resetMap();
        }   
    }
    public void moveCharacter(GameObject player, GameObject tile)
    {
        if (tile != null)
        {
            Dictionary<GameObject, int> distances = new Dictionary<GameObject, int>();
            Dictionary<GameObject, bool> visited = new Dictionary<GameObject, bool>();
            Dictionary<GameObject, GameObject> parents = new Dictionary<GameObject, GameObject>();
            Queue<GameObject> newShortestPath = new Queue<GameObject>();

            foreach (GameObject x in tileMap)
            {
                distances.Add(x, int.MaxValue);
                visited.Add(x, false);
                parents.Add(x, null);
            }
            distances[player.GetComponent<entityData>().tileOn] = 0;
            visited[player.GetComponent<entityData>().tileOn] = true;
            findShortestPath(distances, visited, parents, player.GetComponent<entityData>().tileOn, tile);
            GameObject path = tile;
            while (parents[path] != null)
            {
                newShortestPath.Enqueue(path);
                path = parents[path];
            }
            Stack<GameObject> tempStack = new Stack<GameObject>();
            while (newShortestPath.Count > 0)
            {
                tempStack.Push(newShortestPath.Peek());
                newShortestPath.Dequeue();
            }
            while (tempStack.Count > 0)
            {
                newShortestPath.Enqueue(tempStack.Peek());
                tempStack.Pop();
            }
            if (shortestPath.Count != 0)
            {
                if (newShortestPath.Count < shortestPath.Count)
                {
                    shortestPath = newShortestPath;
                }
            }
            else
            {
                shortestPath = newShortestPath;
            }
            player.GetComponent<entityData>().tileOn.GetComponent<TileData>().entityOn = null;
        }
    }
    public RoundController.roundStateEnum moveAlongPath(GameObject player)
    {
        if (player.tag == "Enemy")
        {
            inEnemyRange = EnemyInRange(player);
        }
        if (shortestPath.Count > 0 && currentPlayerData.movementPoints > 0 && !inEnemyRange)
        {
            if (!moving)
            {
                currentPlayerData.movementPoints--;
                movingToward = shortestPath.Dequeue();
                moving = true;
            } else
            {
                if (player.transform.position == movingToward.transform.position)
                {
                    moving = false;
                } else
                {
                    player.transform.position = Vector3.MoveTowards(player.transform.position, movingToward.transform.position, characterSpeed);
                }
            }
        } else
        {
            if(!moving)
            {
                currentPlayerData.movementPoints--;
                movingToward = shortestPath.Dequeue();
                moving = true;
            } else
            {
                if (player.transform.position == movingToward.transform.position)
                {
                    moving = false;
                    moved = true;
                }
                else
                {
                    player.transform.position = Vector3.MoveTowards(player.transform.position, movingToward.transform.position, characterSpeed);
                }
            }
        }
        if (player.tag == "Player")
        {
            if (moved)
            {
                if (action)
                {
                    return RoundController.roundStateEnum.CharacterEnd;
                }
                else
                {
                    resetMap();
                    roundController.playerRound = RoundController.playerStates.playerBase;
                    playerUI.SetActive(true);
                    return RoundController.roundStateEnum.CharacterTurn;
                }
            }
            else
            {
                return RoundController.roundStateEnum.Movement;
            }
        } else
        {
            if (moved)
            {
                findTileOn();
                FindRangeAttack(player);
                roundController.enemyWait(RoundController.roundStateEnum.CharacterTurn);
                return RoundController.roundStateEnum.EnemyPause;

            } else
            {   
                return RoundController.roundStateEnum.EnemyMovement;
            }
        }
    }
    public void resetMap()
    {
        foreach(GameObject x in tileMap)
        {
            TileData tiledata = x.GetComponent<TileData>();
            tiledata.inRange = false;
            tiledata.inAttackRange = false;
            tiledata.entityOn = null;
            SpriteRenderer rend = x.GetComponent<SpriteRenderer>();
            rend.material.color = Color.white; 
        }
        selectedTile = false;
        moved = false;
        turnEnd = false;
        tileClicked = null;
        shortestPath = new Queue<GameObject>();
        findTileOn();
        movingNow = false;
    }
    public void setUpMap()
    {
        foreach (GameObject x in tileMap)
        {
            TileData tiledata = x.GetComponent<TileData>();
            foreach (GameObject y in tileMap)
            {
                if (y != x)
                {
                    if (Vector3.Distance(x.transform.position, y.transform.position) < 1.1f)
                    {
                        if (x.transform.position.x < y.transform.position.x)
                        {
                            tiledata.tileWest = y;
                        }
                        else if (x.transform.position.x > y.transform.position.x)
                        {
                            tiledata.tileEast = y;
                        }
                        else if (x.transform.position.y < y.transform.position.y)
                        {
                            tiledata.tileSouth = y;
                        }
                        else if (x.transform.position.y > y.transform.position.y)
                        {
                            tiledata.tileNorth = y;
                        }
                    }
                }
            }
            tiledata.setNeighbors();
        }
    }
    public void findTileOn()
    {
        foreach (GameObject x in players)
        {
            //Logic for if players are dead or not recruited
            //Set player tile on
            if (x.activeInHierarchy)
            {
                entityData data = x.GetComponent<entityData>();
                foreach (GameObject y in tileMap)
                {
                    TileData tiledata = y.GetComponent<TileData>();
                    tiledata.setMap(this);
                    if (data.tileOn == null)
                    {
                        data.tileOn = y;

                    }
                    else
                    {
                        if (Vector3.Distance(x.transform.position, data.tileOn.transform.position) > Vector3.Distance(x.transform.position, y.transform.position))
                        {

                            data.tileOn = y;
                        }
                    }
                }
                data.tileOn.GetComponent<TileData>().entityOn = x;
            }
        }
        foreach (GameObject x in enemies)
        {
            //Logic for if players are dead or not recruited
            //Set player tile on
            if (x.activeInHierarchy)
            {
                entityData data = x.GetComponent<entityData>();
                foreach (GameObject y in tileMap)
                {
                    TileData tiledata = y.GetComponent<TileData>();
                    tiledata.setMap(this);
                    if (data.tileOn == null)
                    {
                        data.tileOn = y;

                    }
                    else
                    {
                        if (Vector3.Distance(x.transform.position, data.tileOn.transform.position) > Vector3.Distance(x.transform.position, y.transform.position))
                        {

                            data.tileOn = y;
                        }
                    }
                }
                data.tileOn.GetComponent<TileData>().entityOn = x;
            }
        }
    }
    public bool EnemyInRange(GameObject player)
    {
        entityData data = player.GetComponent<entityData>();
        if (data.attackRange == 1)
        {
            foreach (GameObject x in players)
            {
                if (Vector3.Distance(player.transform.position, x.transform.position) < 1.5f && x.activeInHierarchy) 
                {
                    return true;
                }
            }
            return false;   
        } else
        {
            return false;
        }
    }
    // Up to 4 players currently supported
    public void setUpHealthUI()
    {
        int count = 0;
        for (int i = 0; i < players.Length; i++) 
        {
            players[i].GetComponent<entityData>().healthBar = healthBars[i];
            healthImages[i].GetComponent<Image>().sprite = players[i].GetComponent<SpriteRenderer>().sprite;
            count++;
        }
        for (int i = count; i < 4; i++)
        {
            healthBars[i].SetActive(false);
            healthImages[i].SetActive(false);
        }
    }

    public void resolveHealthUI()
    {
        foreach(GameObject x in players)
        {
            entityData playerData = x.GetComponent<entityData>();
            playerData.healthBar.GetComponent<Slider>().value = (float) playerData.currentHealth / (float) playerData.maxHealth;
        }
    }

    public bool checkPlayers ()
    {
        bool alive = false;
        foreach(GameObject x in players)
        {
            if (x.activeInHierarchy)
            {
                alive = true;
            }
        }
        return alive;
    }


    public bool checkEnemies()
    {
        bool alive = false;
        foreach (GameObject x in enemies)
        {
            if (x.activeInHierarchy)
            {
                alive = true;
            }
        }
        return alive;
    }
}

