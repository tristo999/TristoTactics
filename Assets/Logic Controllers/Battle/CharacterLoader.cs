using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.SceneManagement;

public class CharacterLoader : MonoBehaviour {

    private readonly string saveDataFile = "saveData1.json";
    private readonly string enemyDataFile = "EnemyData.json";


    private void LoadData()
    {
        string saveFilePath = Path.Combine(Application.streamingAssetsPath, saveDataFile);
        string enemyFilePath = Path.Combine(Application.streamingAssetsPath, enemyDataFile);

        //Save Data Should Be Here But You Know

        if (File.Exists(saveFilePath))
        {

        } else
        {
            Debug.LogError("SAVE FILE DOESNT EXIST");
        }
        if (File.Exists(enemyFilePath))
        {

        }
        else
        {
            Debug.LogError("ENEMY FILE DOESNT EXIST");
        }
    }
}
