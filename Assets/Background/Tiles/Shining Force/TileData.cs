using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TileData : MonoBehaviour {
    public bool passable = true;
    public SpriteRenderer renderer;
    public bool inRange;
    public Map worldMap;
    public GameObject entityOn;
    public GameObject tileNorth;
    public GameObject tileWest;
    public GameObject tileEast;
    public GameObject tileSouth;
    public List<GameObject> neighbors;
    // Use this for initialization
    void Start () {
        renderer = gameObject.GetComponent<SpriteRenderer>();
    }
	
	// Update is called once per frame
	void Update () {
		
	}
    
    private Color startcolor;

    void OnMouseEnter()
    {
        startcolor = renderer.material.color;
        renderer.material.color = Color.yellow;
    }
    void OnMouseExit()
    {
        if (inRange)
        {
            renderer.material.color = Color.gray;
        }
        else
        {
            renderer.material.color = startcolor;
        }
    }
    private void OnMouseDown()
    {
        if (inRange)
        {
            worldMap.selectTile(gameObject);
        }
    }
    public void setMap(Map map)
    {
        this.worldMap = map;
    }
    public void setNeighbors()
    {
        neighbors = new List<GameObject>();
        if (tileNorth != null)
        {
            neighbors.Add(tileNorth);
        }
        if (tileSouth != null)
        {
            neighbors.Add(tileSouth);
        }
        if (tileEast != null)
        {
            neighbors.Add(tileEast);
        }
        if (tileWest != null)
        {
            neighbors.Add(tileWest);
        }
    } 
}
