package Demo;

import javax.swing.*;
import java.awt.*;

public class SpeechPanel6 extends JPanel {

    private SmartAdaptiveClinicalAssistant mainFrame;

    public SpeechPanel6(SmartAdaptiveClinicalAssistant frame) {
        this.mainFrame = frame;
        setBackground(Color.WHITE);
        setLayout(new BorderLayout(10, 10));
        setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // 顶部
        JPanel topPanel = new JPanel(new BorderLayout());
        topPanel.setBackground(Color.WHITE);

        JLabel title = new JLabel("Speech Analysis", SwingConstants.CENTER);
        title.setFont(new Font("Arial", Font.BOLD, 24));
        topPanel.add(title, BorderLayout.CENTER);

        add(topPanel, BorderLayout.NORTH);

        // 中间
        JPanel centerPanel = new JPanel();
        centerPanel.setLayout(new BoxLayout(centerPanel, BoxLayout.Y_AXIS));
        centerPanel.setBackground(Color.WHITE);

        JLabel resultTitle = new JLabel("Analysis Result", SwingConstants.CENTER);
        resultTitle.setFont(new Font("Arial", Font.BOLD, 18));
        resultTitle.setAlignmentX(Component.CENTER_ALIGNMENT);

        JTextArea resultArea = new JTextArea();
        resultArea.setFont(new Font("Arial", Font.PLAIN, 14));
        resultArea.setText("Based on your responses:\n\n" +
                "• Duration: 3 days\n" +
                "• Severity: Moderate to severe\n" +
                "• Other symptoms: Headache, fatigue\n" +
                "• Medication: None taken\n\n" +
                "Recommendation:\n" +
                "Please consult with a healthcare provider for proper evaluation.");
        resultArea.setEditable(false);
        resultArea.setBackground(new Color(245, 248, 250));
        resultArea.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

        centerPanel.add(resultTitle);
        centerPanel.add(Box.createVerticalStrut(20));
        centerPanel.add(resultArea);

        add(centerPanel, BorderLayout.CENTER);

        // 底部
        JPanel bottomPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 20, 10));
        bottomPanel.setBackground(Color.WHITE);

        JButton backBtn = new JButton("← Back");
        backBtn.setFont(new Font("Arial", Font.PLAIN, 14));
        backBtn.addActionListener(e -> mainFrame.showHome());

        JButton homeBtn = new JButton("Finish → Home");
        homeBtn.setFont(new Font("Arial", Font.BOLD, 14));
        homeBtn.setBackground(new Color(41, 98, 255));
        homeBtn.setForeground(Color.WHITE);
        homeBtn.addActionListener(e -> mainFrame.showHome());
//        nextBtn.addActionListener(e -> {
//            // 关键：这里改成 SpeechPanel3
//            mainFrame.getContentPane().removeAll();
//            mainFrame.getContentPane().add(new SpeechPanel3(mainFrame));
//            mainFrame.revalidate();
//            mainFrame.repaint();
//        });
        bottomPanel.add(backBtn);
        bottomPanel.add(homeBtn);
        add(bottomPanel, BorderLayout.SOUTH);
    }
}