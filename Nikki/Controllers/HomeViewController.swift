//
//  ViewController.swift
//  Nikki
//
//  Created by 渡辺雄太 on 2019/12/12.
//  Copyright © 2019 Yuta Watanabe. All rights reserved.
//

import UIKit
import RealmSwift

class HomeViewController: UIViewController {
    // MARK: - Properties
    // Realmを取得
    let realm = try! Realm()
    // セクションに表示する日付を取得
    let items = try! Realm().objects(Section.self).sorted(byKeyPath: "area", ascending: false)
    // String型にダウンキャスト
    var sectionNames: [String] {
        return items.value(forKeyPath: "area") as! [String]
    }
    // セルに表示するデータを取得
    var categorys: Results<Category>?
    
    // MARK: - UI Parts
    // メニュー用ハンバーガーボタン
    private var menuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // DateSourceを設定
        tableView.dataSource = self
        // Delegateを設定
        tableView.delegate = self
        // カスタムセルを設定
        tableView.registerCustomCell()
        // セルの縦幅
        tableView.rowHeight = 120.0
        
        menuButtonPressed()
    }
    // viewが画面に表示されてから呼ばれるメソッド
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 画面が表示される度にロードする
        loadCategories()
    }
    // MARK: - Data Manipulation Methods
    // ロードメソッド
    func loadCategories() {
        // Realmからデータをロード
        categorys = realm.objects(Category.self).sorted(byKeyPath: "sort", ascending: false)
        // テーブルビューをロード
        tableView.reloadData()
    }
    
    // MARK: - Private Function
    // サイドナビゲーションが閉じた状態から左隅のドラッグを行ってコンテンツを開く際の処理
    @objc private func menuButtonPressed() {
        if let parentViewController = self.parent {
            let vc = parentViewController as! BaseViewController
            vc.openSideNavigation()
        }
    }
}

// MARK: - TableView Datasource Methods
extension HomeViewController: UITableViewDataSource {
    
    // 表示するセクションの数を取得
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionNames.count
    }
    // 取得したセクションの数に応じて表示
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionNames[section]
    }
    
    // セルを表示する行数を取得
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 取得した記事の日付と取得したセクションの日付が完全一致する数を取得し、何もなければ１とする
        return categorys?.filter("date == %@", sectionNames[section]).count ?? 1
    }
    // セルを作成
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用するセルを取得
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! ListCell
        // セクションの日付毎に記事を表示させ、タイトルにデータがなければ"No Title"をセルテキストに代入
        cell.titleLabel.text = categorys?.filter("date == %@", sectionNames[indexPath.section])[indexPath.row].index ?? "No Title"
        // 時刻を代入
        cell.timeLabel.text = categorys?.filter("date == %@", sectionNames[indexPath.section])[indexPath.row].hours ?? ""
        
        return cell
    }
    
    
}

// MARK: - TbaleView Delegate Methods
extension HomeViewController: UITableViewDelegate {
    
    // セルが選択されていることを通知する
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 選択したセルに指定した識別子でセグエを開始する
        performSegue(withIdentifier: K.categoryCell, sender: self)
        // セルをタッチした時に選択解除のアニメーションを追加
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // セグエ実行中の処理
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // 遷移先がArticleViewControllerなら選択しているCategoryデータをselectedCategoryに渡す
        if let vc = segue.destination as? ArticleViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                vc.selectedCategory = (categorys?[indexPath.row])!
            }
        }
    }
    // セルをスワイプで削除するメソッド
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "削除") { (ac: UIContextualAction, view: UIView, success: (Bool) -> Void) in
            // 選択したセルにデータが入っていれば削除する
            if let categoryForDeletion = self.categorys?[indexPath.row] {
                do {
                    try! self.realm.write {
                        // 子データから削除する
                        self.realm.delete(categoryForDeletion.articles)
                        self.realm.delete(categoryForDeletion)
                    }
                }
            }
            tableView.reloadData()
            print("削除")
            success(true)
        }
        deleteAction.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
