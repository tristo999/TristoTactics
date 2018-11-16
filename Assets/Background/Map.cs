using System.Collections;
using System.Collections.Generic;
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
    public int currentMove;
    public bool inEnemyRange = false;
    public GameObject movingToward;

    // Use this for initialization
    void Start ()
    {
        tileMap = GameObject.FindGameObjectsWithTag("Environment");
        players = GameObject.FindGameObjectsWithTag("Player");
        enemies = GameObject.FindGameObjectsWithTag("Enemy");
        findTileOn();
        roundController = masterGameObject.GetComponent<RoundController>();
        roundController.StartUp(players, enemies);
	}
	

    void FindRange(GameObject player)
    {
        entityData data = player.GetComponent<entityData>();
        int range = currentMove;
        rangebfs(range,data.tileOn);
        inEnemyRange = false;
    }
    
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

    public void initialPlayerTurn(GameObject player)
    {
        findTileOn();
        currentMove = player.GetComponent<entityData>().movementRange;
        FindRange(player);
    }
    public RoundController.roundStateEnum playerTurn(GameObject player)
    {
        movingNow = false;
        if (!moved)
        {
            if (selectedTile)
            {
                moveCharacter(player, tileClicked);
                movingNow = true;
            }
        }
        if (Input.GetKeyDown(KeyCode.Space))
        {
            action = true;
        }
        if ((moved && action) || turnEnd)
        {
            return RoundController.roundStateEnum.CharacterEnd;
        } else if(movingNow)
        {
            return RoundController.roundStateEnum.Movement;
        }
        else
        {
            return RoundController.roundStateEnum.CharacterTurn;
        }
    }

    public RoundController.roundStateEnum enemyTurn(GameObject player)
    {
        Debug.Log("In Enemy Turn");
        bool inRange = EnemyInRange(player);
          if (inRange) {
            if (action)
            {
                return RoundController.roundStateEnum.CharacterEnd;
            } else
            {
                //Do Action
                Debug.Log("Attack!");
                return RoundController.roundStateEnum.CharacterEnd;
            }
          } else {
               if (!moved) {
                Debug.Log("Moving Enemy");
                GameObject closestPlayer = GameObject.FindGameObjectWithTag("Player");
                foreach (GameObject x in players)
                {
                    if (Vector3.Distance(x.transform.position, player.transform.position) < Vector3.Distance(player.transform.position, closestPlayer.transform.position))
                    {
                        closestPlayer = x;
                    }
                }
                moveCharacter(player, closestPlayer.GetComponent<entityData>().tileOn);
                return RoundController.roundStateEnum.EnemyMovement;

               } else {

                return RoundController.roundStateEnum.CharacterEnd;

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
                if(!visited[x])
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
        Dictionary<GameObject, int> distances = new Dictionary<GameObject, int>();
        Dictionary<GameObject, bool> visited = new Dictionary<GameObject, bool>();
        Dictionary<GameObject, GameObject> parents = new Dictionary<GameObject, GameObject>();
        shortestPath = new Queue<GameObject>();
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
        while(parents[path] != null)
        {
            shortestPath.Enqueue(path);
            path = parents[path];
        }
        Stack<GameObject> tempStack = new Stack<GameObject>();
        while(shortestPath.Count > 0)
        {
            tempStack.Push(shortestPath.Peek());
            shortestPath.Dequeue();
        }
        while (tempStack.Count > 0)
        {
            shortestPath.Enqueue(tempStack.Peek());
            tempStack.Pop();
        }
        player.GetComponent<entityData>().tileOn.GetComponent<TileData>().entityOn = null;
    }
    public RoundController.roundStateEnum moveAlongPath(GameObject player)
    {
        if (player.tag == "Enemy")
        {
            inEnemyRange = EnemyInRange(player);
        }
        if (shortestPath.Count > 0 && currentMove > 0 && !inEnemyRange)
        {
            if (!moving)
            {
                currentMove -= 1;
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
                currentMove -= 1;
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
                return RoundController.roundStateEnum.CharacterTurn;

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
            SpriteRenderer rend = x.GetComponent<SpriteRenderer>();
            rend.material.color = Color.white;
            selectedTile = false;
            moved = false;
            action = false;
            turnEnd = false;
            shortestPath = new Queue<GameObject>();
        }
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
                            Debug.Log("SET WEST");
                        }
                        else if (x.transform.position.x > y.transform.position.x)
                        {
                            tiledata.tileEast = y;
                            Debug.Log("SET EAST");
                        }
                        else if (x.transform.position.y < y.transform.position.y)
                        {
                            tiledata.tileSouth = y;
                            Debug.Log("SET SOUTH");
                        }
                        else if (x.transform.position.y > y.transform.position.y)
                        {
                            tiledata.tileNorth = y;
                            Debug.Log("SET NORTH");
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
        foreach (GameObject x in enemies)
        {
            //Logic for if players are dead or not recruited
            //Set player tile on
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

    public bool EnemyInRange(GameObject player)
    {
        entityData data = player.GetComponent<entityData>();
        if (data.attackRange == 1)
        {
            foreach (GameObject x in players)
            {
                if (Vector3.Distance(player.transform.position, x.transform.position) < 1.5f) 
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
}

