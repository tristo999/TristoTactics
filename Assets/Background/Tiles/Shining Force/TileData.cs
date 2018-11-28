using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TileData : MonoBehaviour {
    public bool passable = true;
    public SpriteRenderer SRenderer;
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
        SRenderer = gameObject.GetComponent<SpriteRenderer>();
    }
	
    private Color startcolor;

    void OnMouseEnter()
    {
        SRenderer.material.color = Color.yellow;
    }
    void OnMouseExit()
    {
        if (inRange)
        {
            SRenderer.material.color = Color.gray;
        }
        else
        {
            SRenderer.material.color = Color.white;
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
