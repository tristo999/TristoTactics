using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Map : MonoBehaviour {

    public GameObject[] tileMap;
    public GameObject[] players;
    public GameObject[] enemies;
    public GameObject masterGameObject;
    public RoundController roundController;
    public GameObject tileClicked;
    public bool selectedTile = false;

    // Use this for initialization
    void Start ()
    {
        tileMap = GameObject.FindGameObjectsWithTag("Environment");
        players = GameObject.FindGameObjectsWithTag("Player");
        //enemies = GameObject.FindGameObjectsWithTag("Enemy");
        /*
        foreach (GameObject x in tileMap)
        {
            Vector3 newPosition = new Vector3(Mathf.RoundToInt(x.transform.position.x), Mathf.RoundToInt(x.transform.position.y),0);
            x.transform.position = newPosition;
        }
        */
        findTileOn();
        roundController = masterGameObject.GetComponent<RoundController>();
        roundController.StartUp(players, enemies);
	}
	
	// Update is called once per frame
	void Update ()
    {
		
	}
   //Im going to need a BFS in here
    void FindPath(GameObject tile1, GameObject tile2)
    {

    }

    void FindRange(GameObject player)
    {
        entityData data = player.GetComponent<entityData>();
        int range = data.movementRange;
        Queue<GameObject> path = new Queue<GameObject>();
        path.Enqueue(data.tileOn);
        rangebfs(range, path);
    }
    void rangebfs(int range, Queue<GameObject> path)
    {
        GameObject current = path.Dequeue();
        if (range != 0)
        {
            foreach (GameObject x in tileMap)
            {
                if (Vector3.Distance(current.transform.position, x.transform.position) < 1.1)
                {
                    TileData tileData = x.GetComponent<TileData>();
                    if (tileData.passable)
                    {
                        path.Enqueue(x);
                        rangebfs(range - 1, path);
                        //current.SetActive(false);
                        SpriteRenderer rend = x.GetComponent<SpriteRenderer>();
                        rend.material.color = Color.gray;
                        tileData.inRange = true;
                    }
                }
            }
        }
    }
    public bool playerTurn(GameObject player)
    {
        findTileOn();
        bool turnOver = false;
        FindRange(player);
        if (selectedTile)
        {
            moveCharacter(player, tileClicked);
            turnOver = true;
            resetMap();
        }
        return turnOver;
    }
    public void selectTile(GameObject tileClicked)
    {
        selectedTile = true;
        this.tileClicked = tileClicked; 

    }
    public void moveCharacter(GameObject player, GameObject tile)
    {
        player.transform.position = tile.transform.position;
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
        }
    }
}

