//
//  TabView.swift
//  IronswornRuleBook
//
//  Created by Lindar Olostur on 15.04.2022.
// 

import SwiftUI
import AVFoundation

public extension Notification.Name {
  static let shakeEnded = Notification.Name("ShakeEnded")
}

public extension UIWindow {
  override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    if motion == .motionShake {
      NotificationCenter.default.post(name: .shakeEnded, object: nil)
    }
    super.motionEnded(motion, with: event)
  }
}

struct ShakeDetector: ViewModifier {
  let onShake: () -> Void

  func body(content: Content) -> some View {
    content
      .onAppear() // this has to be here because of a SwiftUI bug
      .onReceive(NotificationCenter.default.publisher(for: .shakeEnded)) { _ in
        onShake()
      }
  }
}

extension View {
  func onShake(perform action: @escaping () -> Void) -> some View {
    self.modifier(ShakeDetector(onShake: action))
  }
}

var audioPlayer: AVAudioPlayer?

func playSound(sound: String, type: String) {
    if let path = Bundle.main.path(forResource: sound, ofType: type) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.play()
        } catch {
            print("ERROR")
        }
    }
}

struct TabView: View {
    @ObservedObject var selectedTab = LastPage()
    @State var newRoll = false

    var body: some View {
        ZStack {
            VStack {
                Picker("", selection: $selectedTab.selectedTab) {
                                Text("Ironsworn").tag(0)
                                Text("Starfoged").tag(1)
                }
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
                
                switch(selectedTab.selectedTab) {
                    case 0: IronswornView()
                    case 1: StarforgedView()
                default:
                    IronswornView()
                }
            }.navigationViewStyle(StackNavigationViewStyle())
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        playSound(sound: "dice", type: "mp3")
                        newRoll.toggle()
                    }) {
                        Image(systemName: "dice")
                            .frame(width: 60, height: 60)
                            .font(.system(size: 30))
                            .foregroundColor(Color.white)
                            .background(Color.gray)
                            .opacity(0.8)
                            .clipShape(Rectangle())
                            .cornerRadius(10)
                    } .padding(.top, 55)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
            PopResultsView(newRoll: $newRoll)
        }
        
        .onShake { // ADD THIS
            newRoll.toggle()
          }
    }
}
struct PopResultsView: View {
    @StateObject var viewModel: PopResultsViewModel = PopResultsViewModel()
    @Binding var newRoll: Bool
    var body: some View {
        GeometryReader{ geo in
            ZStack{
                //Show bubble views for each bubble
                ForEach(viewModel.pops){pop in
                    PopResultView(pop: pop)
                }
            }.onChange(of: newRoll, perform: { _ in
                viewModel.addPops(frameSize: geo.size)
            })
            
            .onAppear(){
                //Set the initial position from frame size
                viewModel.viewBottom = geo.size.height
//                viewModel.addPops(frameSize: geo.size)
            }
        }
    }
}

class PopResultsViewModel: ObservableObject{
    @Published var viewBottom: CGFloat = CGFloat.zero
    @Published var pops: [PopResultModel] = []
    private var timer: Timer?
    private var timerCount: Int = 0
    @Published var popCount: Int = 0
    
    func addPops(frameSize: CGSize){
        let _: TimeInterval = 2
        //Start timer
        timerCount = 0
        if timer != nil{
            timer?.invalidate()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
            let pop = PopResultModel()
            //Add to array
            self.pops.append(pop)
            //Get rid if the bubble at the end of its lifetime
            Timer.scheduledTimer(withTimeInterval: pop.lifetime, repeats: false, block: {_ in
                self.pops.removeAll(where: {
                    $0.id == pop.id
                })
            })
            if self.timerCount >= self.popCount {
                //Stop when the bubbles will get cut off by screen
                timer.invalidate()
                self.timer = nil
            }else{
                self.timerCount += 1
            }
        }
    }
}

struct PopResultView: View {
    //If you want to change the bubble's variables you need to observe it
    @ObservedObject var pop: PopResultModel
    @State var opacity: Double = 0
    var match: Bool {
        if pop.number % 11 == 0 {
            return true
        } else {
            return false
        }
    }
    var body: some View {
        Text("\(pop.number)")
            .frame(width: pop.width, height: pop.height)
            .font(.system(size: 38))
            .background(match ? Color.red : Color.teal)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .opacity(opacity)
            .position(x: pop.x, y: pop.y)
            .onAppear {

                withAnimation(.linear(duration: pop.lifetime)){
                    //Go up
                    self.pop.y = -pop.height
                    //Go sideways
                    //self.pop.x += pop.xFinalValue()
                    //Change size
                    //let width = pop.yFinalValue()
                    self.pop.width = 120
                    self.pop.height = 70
                    
                }
                //Change the opacity faded to full to faded
                //It is separate because it is half the duration
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    withAnimation(Animation.interactiveSpring(response: 0.2, dampingFraction: 6.0, blendDuration: 5.0).repeatForever()) {
                        self.opacity = 1
                    }
//                    withAnimation(.linear(duration: pop.lifetime/4).repeatForever(autoreverses: true)) {
//                        self.opacity = 1
//                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    withAnimation(Animation.linear(duration: pop.lifetime/4).repeatForever()) {
                        //Go sideways
                        //pop.x += pop.xFinalValue()
                    }
                }
            }
    }
}

class PopResultModel: Identifiable, ObservableObject{
    let id: UUID = UUID()
    @Published var x: CGFloat
    @Published var y: CGFloat
    //@Published var color: Color
    @Published var width: CGFloat
    @Published var height: CGFloat
    @Published var lifetime: TimeInterval = 0
    @Published var number: Int
    @Published var fontSize: Int
    @State var match = false
    init(){
        self.height = 50
        self.width = 70
        //self.color = .red
        self.x = 200
        self.y = 800
        self.lifetime = 3
        self.number = Int.random(in: 1...100)
        self.fontSize = 40
    }
    func xFinalValue() -> CGFloat {
        return CGFloat.random(in:-30*CGFloat(lifetime*1.5)...30*CGFloat(lifetime*1.5))
    }
    func yFinalValue() -> CGFloat {
        return CGFloat.random(in:0...width*CGFloat(lifetime*2.5))
    }
    
}

struct TabView_Previews: PreviewProvider {
    static var previews: some View {
        TabView()
    }
}

class LastPage: ObservableObject {
    @Published var selectedTab: Int = UserDefaults.standard.integer(forKey: "lastTab") {
        didSet {
            UserDefaults.standard.set(self.selectedTab, forKey: "lastTab")
        }
    }
}
