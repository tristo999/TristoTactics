using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TileData : MonoBehaviour {
    public bool passable = true;
    private SpriteRenderer renderer;
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
    
}
