using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TileData : MonoBehaviour {
    public bool passable = true;
    private SpriteRenderer renderer;
    public bool inRange;
    public Map worldMap;
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
        renderer.material.color = startcolor;
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
}
