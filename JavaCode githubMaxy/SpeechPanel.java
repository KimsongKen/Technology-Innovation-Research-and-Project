package Demo;

import javax.swing.*;
import java.awt.*;

public class SpeechPanel extends JPanel {

    private SmartAdaptiveClinicalAssistant mainFrame;
    private JTextArea textArea;
    private JButton recordBtn;
    private boolean recording = false;

    public SpeechPanel(SmartAdaptiveClinicalAssistant frame) {
        this.mainFrame = frame;
        setBackground(Color.WHITE);
        setLayout(new BorderLayout(10, 10));
        setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // 顶部
        JPanel topPanel = new JPanel(new BorderLayout());
        topPanel.setBackground(Color.WHITE);

        JButton backBtn = new JButton("← Back");
        backBtn.addActionListener(e -> mainFrame.showHome());
        topPanel.add(backBtn, BorderLayout.WEST);

        JLabel title = new JLabel("Speech", SwingConstants.CENTER);
        title.setFont(new Font("Arial", Font.BOLD, 24));
        topPanel.add(title, BorderLayout.CENTER);

        add(topPanel, BorderLayout.NORTH);

        // 中间
        JPanel centerPanel = new JPanel(new BorderLayout(10, 10));
        centerPanel.setBackground(Color.WHITE);

        JLabel prompt = new JLabel("Tell us about your problem?");
        prompt.setFont(new Font("Arial", Font.PLAIN, 14));
        centerPanel.add(prompt, BorderLayout.NORTH);

        textArea = new JTextArea();
        textArea.setFont(new Font("Arial", Font.PLAIN, 14));
        textArea.setLineWrap(true);
        textArea.setWrapStyleWord(true);
        textArea.setEditable(false);
        textArea.setText("Click Start Recording...");
        textArea.setBorder(BorderFactory.createLineBorder(Color.LIGHT_GRAY));

        JScrollPane scroll = new JScrollPane(textArea);
        scroll.setPreferredSize(new Dimension(400, 150));
        centerPanel.add(scroll, BorderLayout.CENTER);

        add(centerPanel, BorderLayout.CENTER);

        // 底部 - 三个按钮
        JPanel bottomPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 20, 10));
        bottomPanel.setBackground(Color.WHITE);

        JButton backBtn2 = new JButton("← Back");
        backBtn2.setFont(new Font("Arial", Font.PLAIN, 14));
        backBtn2.addActionListener(e -> mainFrame.showHome());

        recordBtn = new JButton("🎤 Start Recording");
        recordBtn.setFont(new Font("Arial", Font.PLAIN, 16));
        recordBtn.setPreferredSize(new Dimension(200, 50));
        recordBtn.addActionListener(e -> toggleRecording());

        JButton nextBtn = new JButton("Next →");
        nextBtn.setFont(new Font("Arial", Font.PLAIN, 14));
        nextBtn.addActionListener(e -> {
            // 直接创建并切换到下一页
            mainFrame.getContentPane().removeAll();
            mainFrame.getContentPane().add(new SpeechPanel2(mainFrame));
            mainFrame.revalidate();
            mainFrame.repaint();
        });

        bottomPanel.add(backBtn2);
        bottomPanel.add(recordBtn);
        bottomPanel.add(nextBtn);
        add(bottomPanel, BorderLayout.SOUTH);
    }

    private void toggleRecording() {
        recording = !recording;
        if (recording) {
            recordBtn.setText("⏹ Stop Recording");
            textArea.setText("");
            new Timer(1000, e -> {
                if (recording) {
                    textArea.setText(textArea.getText() + "Patient says... ");
                } else {
                    ((Timer)e.getSource()).stop();
                }
            }).start();
        } else {
            recordBtn.setText("🎤 Start Recording");
        }
    }
}