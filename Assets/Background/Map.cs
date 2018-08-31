using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Map : MonoBehaviour {

    public GameObject[] tileMap;
    public GameObject[] players;
    public GameObject[] enemies;
    public GameObject masterGameObject;
    public RoundController roundController;

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
        foreach (GameObject x in players) {
            //Logic for if players are dead or not recruited
            //Set player tile on
            entityData data = x.GetComponent<entityData>();
            foreach (GameObject y in tileMap)
            {
                if(data.tileOn == null)
                {
                    data.tileOn = y;
                } else
                {
                    if(Vector3.Distance(x.transform.position,data.tileOn.transform.position) > Vector3.Distance(x.transform.position, y.transform.position))
                    {
                        data.tileOn = y;
                    }
                }
            }
            //FindRangeCheck
            FindRange(x);
        }
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
                    }
                }
            }
        }
    }
}

